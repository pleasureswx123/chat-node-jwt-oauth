# Windows 部署快速参考

## 一键部署

```powershell
# 开发环境快速启动
.\bootstrap.ps1

# 生产环境部署
.\deploy.ps1

# 安装为 Windows 服务(需要管理员权限)
.\install-service.ps1
```

---

## PM2 常用命令

```powershell
# 查看所有进程
pm2 list
pm2 status

# 查看日志
pm2 logs                          # 所有日志
pm2 logs coze-oauth-service       # 特定服务日志
pm2 logs --lines 100              # 最近 100 行

# 进程管理
pm2 start ecosystem.config.js     # 启动
pm2 restart coze-oauth-service    # 重启
pm2 stop coze-oauth-service       # 停止
pm2 delete coze-oauth-service     # 删除

# 监控
pm2 monit                         # 实时监控
pm2 show coze-oauth-service       # 详细信息

# 保存配置
pm2 save                          # 保存当前进程列表
pm2 resurrect                     # 恢复保存的进程列表
```

---

## Windows 服务管理

```powershell
# 服务控制(需要管理员权限)
Start-Service PM2                 # 启动服务
Stop-Service PM2                  # 停止服务
Restart-Service PM2               # 重启服务
Get-Service PM2                   # 查看状态

# 设置自动启动
Set-Service -Name PM2 -StartupType Automatic
```

---

## 健康检查

```powershell
# 手动健康检查
.\health-check.ps1

# 设置定时检查(需要管理员权限)
.\setup-monitoring.ps1

# 查看检查日志
Get-Content .\logs\health-check.log -Tail 50
```

---

## 备份与恢复

```powershell
# 备份配置
.\backup.ps1

# 备份配置和日志
.\backup.ps1 -IncludeLogs

# 恢复备份
Copy-Item -Path .\backups\<timestamp>\* -Destination . -Recurse -Force
```

---

## 故障排查

### 1. 查看错误日志
```powershell
pm2 logs coze-oauth-service --err
Get-Content .\logs\err.log -Tail 50
```

### 2. 检查端口占用
```powershell
netstat -ano | findstr :8080
```

### 3. 结束占用端口的进程
```powershell
taskkill /PID <进程ID> /F
```

### 4. 重启服务
```powershell
pm2 restart coze-oauth-service
```

### 5. 完全重新部署
```powershell
pm2 delete coze-oauth-service
.\deploy.ps1
```

---

## 更新部署

```powershell
# 1. 备份当前配置
.\backup.ps1

# 2. 拉取最新代码(如果使用 Git)
git pull

# 3. 安装依赖
npm install --production

# 4. 重启服务
pm2 restart coze-oauth-service

# 5. 查看日志确认
pm2 logs coze-oauth-service --lines 50
```

---

## 性能优化

### 启用集群模式
编辑 `ecosystem.config.js`:
```javascript
instances: 'max',        // 使用所有 CPU 核心
exec_mode: 'cluster'     // 集群模式
```

### 配置日志轮转
```powershell
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
```

---

## 防火墙配置

```powershell
# 开放端口(需要管理员权限)
New-NetFirewallRule -DisplayName "Coze OAuth Service" `
  -Direction Inbound `
  -LocalPort 8080 `
  -Protocol TCP `
  -Action Allow

# 查看规则
Get-NetFirewallRule -DisplayName "Coze OAuth Service"

# 删除规则
Remove-NetFirewallRule -DisplayName "Coze OAuth Service"
```

---

## 环境变量

```powershell
# 临时设置(当前会话)
$env:PORT = "8080"
$env:NODE_ENV = "production"

# 永久设置(需要管理员权限)
[Environment]::SetEnvironmentVariable("PORT", "8080", "Machine")
[Environment]::SetEnvironmentVariable("NODE_ENV", "production", "Machine")

# 查看环境变量
Get-ChildItem Env:
```

---

## 卸载

```powershell
# 停止并删除服务
pm2 delete coze-oauth-service

# 卸载 Windows 服务(需要管理员权限)
.\uninstall-service.ps1

# 删除 PM2
npm uninstall -g pm2
npm uninstall -g pm2-windows-service
```

---

## 常见问题

**Q: PM2 命令找不到?**
```powershell
# 查看 npm 全局目录
npm config get prefix

# 添加到 PATH
$npmPath = npm config get prefix
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$npmPath", "Machine")
```

**Q: 服务无法启动?**
1. 检查配置文件是否存在
2. 查看错误日志
3. 检查端口是否被占用
4. 验证 Node.js 版本 >= 14

**Q: 外网无法访问?**
1. 检查防火墙规则
2. 修改监听地址为 `0.0.0.0`
3. 检查云服务器安全组设置

---

## 获取帮助

- 详细部署文档: [DEPLOYMENT.md](./DEPLOYMENT.md)
- PM2 官方文档: https://pm2.keymetrics.io/
- Node.js 官方文档: https://nodejs.org/

