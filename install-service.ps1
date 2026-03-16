#!/usr/bin/env pwsh
# 将应用安装为 Windows 服务
# 需要管理员权限运行

# 检查管理员权限
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "此脚本需要管理员权限运行"
    Write-Host "请右键点击 PowerShell,选择'以管理员身份运行',然后重新执行此脚本" -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "安装 Coze OAuth 服务为 Windows 服务" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 检查 PM2 是否安装
Write-Host "`n[1/3] 检查 PM2..." -ForegroundColor Yellow
if (-not (Get-Command pm2 -ErrorAction SilentlyContinue)) {
    Write-Host "PM2 未安装,正在安装..." -ForegroundColor Yellow
    npm install -g pm2
}
Write-Host "✓ PM2 已安装" -ForegroundColor Green

# 2. 检查 pm2-windows-service 是否安装
Write-Host "`n[2/3] 检查 pm2-windows-service..." -ForegroundColor Yellow
if (-not (Get-Command pm2-service-install -ErrorAction SilentlyContinue)) {
    Write-Host "pm2-windows-service 未安装,正在安装..." -ForegroundColor Yellow
    npm install -g pm2-windows-service
}
Write-Host "✓ pm2-windows-service 已安装" -ForegroundColor Green

# 3. 安装 PM2 为 Windows 服务
Write-Host "`n[3/3] 安装 PM2 为 Windows 服务..." -ForegroundColor Yellow
Write-Host "注意: 安装过程中会提示输入服务名称和账户信息" -ForegroundColor Yellow
Write-Host "建议使用默认值(直接按回车)" -ForegroundColor Yellow

pm2-service-install

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Windows 服务安装完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n下一步操作:" -ForegroundColor Yellow
Write-Host "1. 运行部署脚本启动应用: .\deploy.ps1" -ForegroundColor White
Write-Host "2. 保存 PM2 进程列表: pm2 save" -ForegroundColor White
Write-Host "3. 服务将在系统重启后自动启动" -ForegroundColor White

Write-Host "`n服务管理命令:" -ForegroundColor Yellow
Write-Host "  启动服务: Start-Service PM2" -ForegroundColor White
Write-Host "  停止服务: Stop-Service PM2" -ForegroundColor White
Write-Host "  重启服务: Restart-Service PM2" -ForegroundColor White
Write-Host "  查看状态: Get-Service PM2" -ForegroundColor White

