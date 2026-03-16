#!/usr/bin/env pwsh
# Windows 服务器部署脚本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "开始部署 Coze OAuth 服务" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 检查 Node.js 是否安装
Write-Host "`n[1/6] 检查 Node.js 环境..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "错误: 未安装 Node.js"
    Write-Host "请访问 https://nodejs.org/ 下载并安装 Node.js (建议 LTS 版本)" -ForegroundColor Red
    exit 1
}

$nodeVersion = (node -v).Substring(1)
Write-Host "✓ Node.js 版本: $nodeVersion" -ForegroundColor Green

# 2. 检查 PM2 是否安装
Write-Host "`n[2/6] 检查 PM2..." -ForegroundColor Yellow
if (-not (Get-Command pm2 -ErrorAction SilentlyContinue)) {
    Write-Host "PM2 未安装,正在安装..." -ForegroundColor Yellow
    npm install -g pm2
    if ($LASTEXITCODE -ne 0) {
        Write-Error "PM2 安装失败"
        exit 1
    }
}
Write-Host "✓ PM2 已安装" -ForegroundColor Green

# 3. 检查配置文件
Write-Host "`n[3/6] 检查配置文件..." -ForegroundColor Yellow
if (-not (Test-Path "coze_oauth_config.json")) {
    Write-Error "错误: 配置文件 coze_oauth_config.json 不存在"
    Write-Host "请创建配置文件并填入正确的配置信息" -ForegroundColor Red
    exit 1
}
Write-Host "✓ 配置文件存在" -ForegroundColor Green

# 4. 创建日志目录
Write-Host "`n[4/6] 创建日志目录..." -ForegroundColor Yellow
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}
Write-Host "✓ 日志目录已创建" -ForegroundColor Green

# 5. 安装依赖
Write-Host "`n[5/6] 安装项目依赖..." -ForegroundColor Yellow
npm install --production
if ($LASTEXITCODE -ne 0) {
    Write-Error "依赖安装失败"
    exit 1
}
Write-Host "✓ 依赖安装完成" -ForegroundColor Green

# 6. 启动服务
Write-Host "`n[6/6] 启动服务..." -ForegroundColor Yellow

# 停止旧服务(如果存在)
pm2 delete coze-oauth-service 2>$null

# 启动新服务
pm2 start ecosystem.config.js

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ 服务启动成功!" -ForegroundColor Green
    
    # 保存 PM2 进程列表
    pm2 save
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "部署完成!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "`n常用命令:" -ForegroundColor Yellow
    Write-Host "  查看服务状态: pm2 status" -ForegroundColor White
    Write-Host "  查看日志:     pm2 logs coze-oauth-service" -ForegroundColor White
    Write-Host "  重启服务:     pm2 restart coze-oauth-service" -ForegroundColor White
    Write-Host "  停止服务:     pm2 stop coze-oauth-service" -ForegroundColor White
    Write-Host "  删除服务:     pm2 delete coze-oauth-service" -ForegroundColor White
    Write-Host "`n服务地址: http://127.0.0.1:8080" -ForegroundColor Cyan
} else {
    Write-Error "服务启动失败,请查看错误信息"
    exit 1
}

