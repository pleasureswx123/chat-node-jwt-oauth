#!/usr/bin/env pwsh
# 备份脚本 - 备份配置文件和日志

param(
    [string]$BackupDir = ".\backups",
    [switch]$IncludeLogs = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "备份 Coze OAuth 服务" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 创建备份目录
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = Join-Path $BackupDir $timestamp

if (-not (Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Write-Host "`n✓ 创建备份目录: $backupPath" -ForegroundColor Green
}

# 备份配置文件
Write-Host "`n[1/3] 备份配置文件..." -ForegroundColor Yellow
$configFiles = @(
    "coze_oauth_config.json",
    "ecosystem.config.js",
    "package.json",
    "package-lock.json"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Copy-Item -Path $file -Destination $backupPath -Force
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ! $file (不存在,跳过)" -ForegroundColor Yellow
    }
}

# 备份 PM2 配置
Write-Host "`n[2/3] 备份 PM2 配置..." -ForegroundColor Yellow
if (Get-Command pm2 -ErrorAction SilentlyContinue) {
    $pm2ConfigPath = Join-Path $backupPath "pm2-dump.json"
    pm2 save
    
    # 查找 PM2 dump 文件
    $pm2Home = $env:PM2_HOME
    if (-not $pm2Home) {
        $pm2Home = Join-Path $env:USERPROFILE ".pm2"
    }
    
    $dumpFile = Join-Path $pm2Home "dump.pm2"
    if (Test-Path $dumpFile) {
        Copy-Item -Path $dumpFile -Destination $pm2ConfigPath -Force
        Write-Host "  ✓ PM2 进程列表已备份" -ForegroundColor Green
    }
} else {
    Write-Host "  ! PM2 未安装,跳过" -ForegroundColor Yellow
}

# 备份日志文件(可选)
Write-Host "`n[3/3] 备份日志文件..." -ForegroundColor Yellow
if ($IncludeLogs -and (Test-Path "logs")) {
    $logsBackupPath = Join-Path $backupPath "logs"
    Copy-Item -Path "logs" -Destination $logsBackupPath -Recurse -Force
    Write-Host "  ✓ 日志文件已备份" -ForegroundColor Green
} else {
    Write-Host "  ! 跳过日志备份 (使用 -IncludeLogs 参数包含日志)" -ForegroundColor Yellow
}

# 创建备份信息文件
$backupInfo = @{
    Timestamp = $timestamp
    Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Files = $configFiles
    IncludeLogs = $IncludeLogs
    NodeVersion = (node -v)
    PM2Version = if (Get-Command pm2 -ErrorAction SilentlyContinue) { (pm2 -v) } else { "Not installed" }
} | ConvertTo-Json

$backupInfo | Out-File -FilePath (Join-Path $backupPath "backup-info.json") -Encoding UTF8

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✓ 备份完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n备份位置: $backupPath" -ForegroundColor Cyan
Write-Host "`n恢复命令:" -ForegroundColor Yellow
Write-Host "  Copy-Item -Path '$backupPath\*' -Destination '.' -Recurse -Force" -ForegroundColor White

# 清理旧备份(保留最近 7 个)
Write-Host "`n清理旧备份..." -ForegroundColor Yellow
$allBackups = Get-ChildItem -Path $BackupDir -Directory | Sort-Object Name -Descending
if ($allBackups.Count -gt 7) {
    $toDelete = $allBackups | Select-Object -Skip 7
    foreach ($old in $toDelete) {
        Remove-Item -Path $old.FullName -Recurse -Force
        Write-Host "  ✓ 删除旧备份: $($old.Name)" -ForegroundColor Gray
    }
}

exit 0

