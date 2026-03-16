#!/usr/bin/env pwsh
# 卸载 Windows 服务
# 需要管理员权限运行

# 检查管理员权限
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "此脚本需要管理员权限运行"
    Write-Host "请右键点击 PowerShell,选择'以管理员身份运行',然后重新执行此脚本" -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "卸载 Coze OAuth Windows 服务" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 停止并删除 PM2 应用
Write-Host "`n[1/3] 停止并删除 PM2 应用..." -ForegroundColor Yellow
if (Get-Command pm2 -ErrorAction SilentlyContinue) {
    pm2 delete all
    pm2 save --force
    Write-Host "✓ PM2 应用已删除" -ForegroundColor Green
} else {
    Write-Host "! PM2 未安装,跳过" -ForegroundColor Yellow
}

# 2. 卸载 PM2 Windows 服务
Write-Host "`n[2/3] 卸载 PM2 Windows 服务..." -ForegroundColor Yellow
if (Get-Command pm2-service-uninstall -ErrorAction SilentlyContinue) {
    pm2-service-uninstall
    Write-Host "✓ Windows 服务已卸载" -ForegroundColor Green
} else {
    Write-Host "! pm2-windows-service 未安装,跳过" -ForegroundColor Yellow
}

# 3. 清理日志文件(可选)
Write-Host "`n[3/3] 是否清理日志文件?" -ForegroundColor Yellow
$cleanup = Read-Host "输入 Y 清理日志,其他键跳过"
if ($cleanup -eq "Y" -or $cleanup -eq "y") {
    if (Test-Path "logs") {
        Remove-Item -Path "logs" -Recurse -Force
        Write-Host "✓ 日志文件已清理" -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "卸载完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

