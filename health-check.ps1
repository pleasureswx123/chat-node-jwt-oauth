#!/usr/bin/env pwsh
# 健康检查脚本 - 检查服务是否正常运行

param(
    [string]$Url = "http://127.0.0.1:8080",
    [int]$Timeout = 5
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Coze OAuth 服务健康检查" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. 检查 PM2 进程状态
Write-Host "`n[1/3] 检查 PM2 进程状态..." -ForegroundColor Yellow
if (Get-Command pm2 -ErrorAction SilentlyContinue) {
    $pm2Status = pm2 jlist | ConvertFrom-Json
    $app = $pm2Status | Where-Object { $_.name -eq "coze-oauth-service" }
    
    if ($app) {
        if ($app.pm2_env.status -eq "online") {
            Write-Host "✓ PM2 进程状态: 运行中" -ForegroundColor Green
            Write-Host "  - 进程 ID: $($app.pid)" -ForegroundColor Gray
            Write-Host "  - 运行时间: $($app.pm2_env.pm_uptime)" -ForegroundColor Gray
            Write-Host "  - 重启次数: $($app.pm2_env.restart_time)" -ForegroundColor Gray
        } else {
            Write-Host "✗ PM2 进程状态: $($app.pm2_env.status)" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✗ 未找到 coze-oauth-service 进程" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "! PM2 未安装,跳过进程检查" -ForegroundColor Yellow
}

# 2. 检查端口监听
Write-Host "`n[2/3] 检查端口监听..." -ForegroundColor Yellow
$port = ([System.Uri]$Url).Port
$listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue

if ($listening) {
    Write-Host "✓ 端口 $port 正在监听" -ForegroundColor Green
} else {
    Write-Host "✗ 端口 $port 未监听" -ForegroundColor Red
    exit 1
}

# 3. 检查 HTTP 响应
Write-Host "`n[3/3] 检查 HTTP 响应..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $Url -TimeoutSec $Timeout -UseBasicParsing
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ HTTP 响应正常 (状态码: $($response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "✗ HTTP 响应异常 (状态码: $($response.StatusCode))" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ HTTP 请求失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. 检查内存使用
Write-Host "`n[额外] 资源使用情况..." -ForegroundColor Yellow
if ($app) {
    $memoryMB = [math]::Round($app.monit.memory / 1MB, 2)
    $cpu = $app.monit.cpu
    
    Write-Host "  - 内存使用: $memoryMB MB" -ForegroundColor Gray
    Write-Host "  - CPU 使用: $cpu%" -ForegroundColor Gray
    
    # 内存告警(超过 500MB)
    if ($memoryMB -gt 500) {
        Write-Host "  ⚠ 警告: 内存使用较高" -ForegroundColor Yellow
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✓ 所有检查通过,服务运行正常!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n服务地址: $Url" -ForegroundColor Cyan

exit 0

