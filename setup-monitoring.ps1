#!/usr/bin/env pwsh
# 设置定时健康检查任务
# 需要管理员权限运行

# 检查管理员权限
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "此脚本需要管理员权限运行"
    Write-Host "请右键点击 PowerShell,选择'以管理员身份运行',然后重新执行此脚本" -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "设置服务监控任务" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$taskName = "CozeOAuthHealthCheck"
$scriptPath = Join-Path $PSScriptRoot "health-check.ps1"
$logPath = Join-Path $PSScriptRoot "logs\health-check.log"

# 确保日志目录存在
$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# 检查任务是否已存在
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "`n任务 '$taskName' 已存在" -ForegroundColor Yellow
    $overwrite = Read-Host "是否覆盖? (Y/N)"
    if ($overwrite -ne "Y" -and $overwrite -ne "y") {
        Write-Host "操作已取消" -ForegroundColor Yellow
        exit 0
    }
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# 创建任务操作
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" >> `"$logPath`" 2>&1"

# 创建任务触发器(每 5 分钟执行一次)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)

# 创建任务设置
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

# 注册任务
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "定期检查 Coze OAuth 服务健康状态" `
    -User "SYSTEM" `
    -RunLevel Highest

Write-Host "`n✓ 监控任务创建成功!" -ForegroundColor Green
Write-Host "`n任务详情:" -ForegroundColor Yellow
Write-Host "  - 任务名称: $taskName" -ForegroundColor White
Write-Host "  - 执行间隔: 每 5 分钟" -ForegroundColor White
Write-Host "  - 日志文件: $logPath" -ForegroundColor White

Write-Host "`n管理命令:" -ForegroundColor Yellow
Write-Host "  查看任务: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor White
Write-Host "  启动任务: Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor White
Write-Host "  停止任务: Stop-ScheduledTask -TaskName '$taskName'" -ForegroundColor White
Write-Host "  删除任务: Unregister-ScheduledTask -TaskName '$taskName'" -ForegroundColor White
Write-Host "  查看日志: Get-Content '$logPath' -Tail 50" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "设置完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

