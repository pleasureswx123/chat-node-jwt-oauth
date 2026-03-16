# Windows 服务器部署指南

本文档详细说明如何在 Windows 服务器上部署 Coze OAuth Node.js 后端服务。

## 目录
- [环境准备](#环境准备)
- [方案一:使用 PM2(推荐)](#方案一使用-pm2推荐)
- [方案二:使用 Windows 服务](#方案二使用-windows-服务)
- [方案三:使用 IIS + iisnode](#方案三使用-iis--iisnode)
- [常见问题](#常见问题)

---

## 环境准备

### 1. 安装 Node.js

1. 访问 [Node.js 官网](https://nodejs.org/)
2. 下载 LTS 版本(推荐 18.x 或更高版本)
3. 运行安装程序,确保勾选 "Add to PATH"
4. 验证安装:
   ```powershell
   node -v
   npm -v
   ```

### 2. 配置防火墙

如果需要外网访问,需要开放端口:

```powershell
# 以管理员身份运行 PowerShell
New-NetFirewallRule -DisplayName "Node.js App Port 8080" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

### 3. 准备配置文件

确保 `coze_oauth_config.json` 文件存在并配置正确:

```json
{
  "client_type": "jwt",
  "client_id": "your_client_id",
  "public_key_id": "your_public_key_id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
  "coze_www_base": "https://www.coze.cn",
  "coze_api_base": "https://api.coze.cn"
}
```

---

## 方案一:使用 PM2(推荐)

PM2 是 Node.js 生产环境最流行的进程管理工具。

### 快速部署

1. **运行部署脚本**
   ```powershell
   cd coze_oauth_nodejs_jwt
   .\deploy.ps1
   ```

2. **验证服务**
   ```powershell
   pm2 status
   pm2 logs coze-oauth-service
   ```

3. **访问服务**
   打开浏览器访问: http://localhost:8080

### 手动部署步骤

如果自动脚本失败,可以手动执行:

```powershell
# 1. 全局安装 PM2
npm install -g pm2

# 2. 安装项目依赖
npm install --production

# 3. 创建日志目录
New-Item -ItemType Directory -Path logs -Force

# 4. 启动服务
pm2 start ecosystem.config.js

# 5. 保存进程列表
pm2 save

# 6. 查看状态
pm2 status
```

### PM2 常用命令

```powershell
# 查看所有进程
pm2 list

# 查看实时日志
pm2 logs coze-oauth-service

# 查看最近 100 行日志
pm2 logs coze-oauth-service --lines 100

# 重启服务
pm2 restart coze-oauth-service

# 停止服务
pm2 stop coze-oauth-service

# 删除服务
pm2 delete coze-oauth-service

# 监控资源使用
pm2 monit
```

---

## 方案二:使用 Windows 服务

将应用注册为 Windows 系统服务,实现开机自启动。

### 安装步骤

1. **以管理员身份运行 PowerShell**
   右键点击 PowerShell 图标 → "以管理员身份运行"

2. **运行安装脚本**
   ```powershell
   cd coze_oauth_nodejs_jwt
   .\install-service.ps1
   ```

3. **部署应用**
   ```powershell
   .\deploy.ps1
   pm2 save
   ```

4. **验证服务**
   ```powershell
   Get-Service PM2
   pm2 status
   ```

### Windows 服务管理

```powershell
# 启动服务
Start-Service PM2

# 停止服务
Stop-Service PM2

# 重启服务
Restart-Service PM2

# 查看服务状态
Get-Service PM2

# 设置服务自动启动
Set-Service -Name PM2 -StartupType Automatic
```

---

## 方案三:使用 IIS + iisnode

如果服务器已经运行 IIS,可以使用 iisnode 托管 Node.js 应用。

### 安装 iisnode

1. 下载 [iisnode](https://github.com/Azure/iisnode/releases)
2. 安装 iisnode
3. 在 IIS 中配置网站

### 配置 web.config

在项目根目录创建 `web.config`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="iisnode" path="index.js" verb="*" modules="iisnode"/>
    </handlers>
    <rewrite>
      <rules>
        <rule name="NodeInspector" patternSyntax="ECMAScript" stopProcessing="true">
          <match url="^index.js\/debug[\/]?" />
        </rule>
        <rule name="StaticContent">
          <action type="Rewrite" url="public{REQUEST_URI}"/>
        </rule>
        <rule name="DynamicContent">
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="True"/>
          </conditions>
          <action type="Rewrite" url="index.js"/>
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
```

---

## 常见问题

### 1. 端口被占用

```powershell
# 查看端口占用
netstat -ano | findstr :8080

# 结束进程
taskkill /PID <进程ID> /F
```

### 2. PM2 命令找不到

确保 npm 全局安装目录在 PATH 中:

```powershell
# 查看 npm 全局目录
npm config get prefix

# 添加到 PATH(以管理员身份运行)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Users\<用户名>\AppData\Roaming\npm", "Machine")
```

### 3. 服务无法启动

检查日志文件:
```powershell
# PM2 日志
pm2 logs coze-oauth-service --err

# 应用日志
Get-Content .\logs\err.log -Tail 50
```

### 4. 外网无法访问

1. 检查防火墙规则
2. 修改 `index.js` 监听地址:
   ```javascript
   app.listen(port, '0.0.0.0', () => {
     console.log(`Server running on http://0.0.0.0:${port}`);
   });
   ```

---

## 性能优化建议

1. **使用集群模式**
   修改 `ecosystem.config.js`:
   ```javascript
   instances: 'max',  // 使用所有 CPU 核心
   exec_mode: 'cluster'
   ```

2. **配置日志轮转**
   ```powershell
   pm2 install pm2-logrotate
   pm2 set pm2-logrotate:max_size 10M
   pm2 set pm2-logrotate:retain 7
   ```

3. **监控和告警**
   ```powershell
   # 安装 PM2 监控
   pm2 install pm2-server-monit
   ```

---

## 安全建议

1. **使用环境变量存储敏感信息**
2. **配置 HTTPS**
3. **限制访问 IP**
4. **定期更新依赖**
   ```powershell
   npm audit
   npm update
   ```

---

## 更新部署

```powershell
# 1. 拉取最新代码
git pull

# 2. 安装依赖
npm install --production

# 3. 重启服务
pm2 restart coze-oauth-service

# 4. 查看日志确认
pm2 logs coze-oauth-service --lines 50
```

