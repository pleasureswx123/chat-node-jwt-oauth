# Coze OAuth Examples

This repository contains examples of different OAuth flows for Coze API authentication.

## Prerequisites

- Node.js 14 or higher
- A Coze API account with client credentials

## Configuration

Each example requires config file to be set with your Coze API credentials:

### JWT OAuth

### Set Environment Variables

To run the JWT OAuth example, set the following config file:

The configuration file should be a JSON file, named coze_oauth_config.json with the following format:

```json
{
  "client_type": "jwt",
  "app_id": "{app_id}",
  "client_id": "{client_id}",
  "client_secret": "{client_secret}",
  "coze_api_base": "https://api.coze.cn"
}
```

This file should be placed in the web-auth directory.

#### Running the Examples

After configuring the config file, you can run the WEB OAuth example using:

```bash
# for mac/linux
sh bootstrap.sh

# for Windows (开发环境)
.\bootstrap.ps1
```

## Production Deployment

### Windows 服务器部署

详细的 Windows 服务器部署指南请查看 [DEPLOYMENT.md](./DEPLOYMENT.md)

#### 快速部署(使用 PM2)

```powershell
# 1. 进入项目目录
cd coze_oauth_nodejs_jwt

# 2. 运行部署脚本
.\deploy.ps1

# 3. 验证服务
pm2 status
```

#### 安装为 Windows 服务(开机自启)

```powershell
# 以管理员身份运行 PowerShell

# 1. 安装 Windows 服务
.\install-service.ps1

# 2. 部署应用
.\deploy.ps1

# 3. 保存 PM2 进程列表
pm2 save
```

#### 常用管理命令

```powershell
# 查看服务状态
pm2 status

# 查看日志
pm2 logs coze-oauth-service

# 重启服务
pm2 restart coze-oauth-service

# 停止服务
pm2 stop coze-oauth-service
```
