# 博客部署指南

本博客使用 **GitHub Actions** 自动构建和部署，你无需在本地安装 Hugo 环境。

## 架构概览

```
本地机器                    GitHub                         你的服务器
   │                          │                               │
   │  git push               │                               │
   ├─────────────────────────►│                               │
   │                          │  GitHub Actions               │
   │                          │  ├─ checkout 代码             │
   │                          │  ├─ 安装 Hugo                 │
   │                          │  └─ 构建静态文件               │
   │                          │                               │
   │                          │  rsync 部署                   │
   │                          ├──────────────────────────────►│
   │                          │                               │  nginx 服务
   │                          │                               │  ├─ 静态文件
   │                          │                               │  └─ 对外提供访问
```

## 首次部署设置

### 第一步：服务器配置

1. **SSH 登录到你的服务器**：
   ```bash
   ssh root@你的服务器IP
   ```

2. **运行初始化脚本** (或手动配置)：
   ```bash
   # 下载并编辑配置
   wget https://raw.githubusercontent.com/你的用户名/你的仓库/main/server/setup.sh
   nano setup.sh  # 修改 DOMAIN, DEPLOY_PATH 等配置
   
   # 运行
   sudo bash setup.sh
   ```

   或者手动操作：
   ```bash
   # 安装 nginx
   apt update && apt install -y nginx
   
   # 创建部署用户和目录
   useradd -m -s /bin/bash deploy
   mkdir -p /var/www/blog
   chown -R deploy:deploy /var/www/blog
   
   # 配置 nginx (复制 server/nginx.conf 内容)
   nano /etc/nginx/sites-available/blog
   ln -s /etc/nginx/sites-available/blog /etc/nginx/sites-enabled/
   rm /etc/nginx/sites-enabled/default
   nginx -t && systemctl restart nginx
   ```

### 第二步：生成 SSH 密钥

在你的**本地机器**执行：

```bash
# 生成专用于部署的 SSH 密钥
ssh-keygen -t ed25519 -f ~/.ssh/blog_deploy -C "github-actions-deploy"

# 将公钥添加到服务器
ssh-copy-id -i ~/.ssh/blog_deploy.pub deploy@你的服务器IP

# 测试连接
ssh -i ~/.ssh/blog_deploy deploy@你的服务器IP
```

### 第三步：配置 GitHub Secrets

1. 进入 GitHub 仓库页面
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**，添加以下 secrets：

| Secret 名称 | 值 |
|------------|---|
| `SSH_PRIVATE_KEY` | 私钥内容: `cat ~/.ssh/blog_deploy` |
| `SERVER_HOST` | 服务器 IP 或域名 |
| `SERVER_USER` | `deploy` |
| `SERVER_PORT` | `22` (或你的 SSH 端口) |
| `DEPLOY_PATH` | `/var/www/blog` |

### 第四步：更新 Hugo 配置

编辑 `hugo.toml`，将 `baseURL` 改为你的域名：

```toml
baseURL = 'https://你的域名/'
```

## 日常使用

### 方式一：使用部署脚本（推荐）

```bash
# 部署并使用自定义提交信息
./deploy.sh "新增了一篇文章"

# 部署并使用默认提交信息
./deploy.sh
```

### 方式二：手动 Git 操作

```bash
git add -A
git commit -m "更新博客"
git push origin main
```

推送后，GitHub Actions 会自动构建并部署。

### 查看部署状态

- 访问: `https://github.com/你的用户名/你的仓库/actions`
- 部署通常在 1-2 分钟内完成

## 在新机器上使用

1. **克隆仓库**：
   ```bash
   git clone https://github.com/你的用户名/你的仓库.git
   cd 你的仓库
   ```

2. **直接部署** (无需安装 Hugo)：
   ```bash
   ./deploy.sh "从新机器部署"
   ```

就这么简单！GitHub Actions 会处理所有构建工作。

## 可选：配置 HTTPS

在服务器上使用 Let's Encrypt 免费证书：

```bash
# 安装 certbot
apt install certbot python3-certbot-nginx

# 获取并配置证书 (自动修改 nginx 配置)
certbot --nginx -d 你的域名

# 设置自动续期
systemctl enable certbot.timer
```

## 文件结构

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions 工作流
├── server/
│   ├── setup.sh            # 服务器初始化脚本
│   └── nginx.conf          # nginx 配置示例
├── deploy.sh               # 本地一键部署脚本
├── content/                # 博客内容
├── themes/                 # Hugo 主题
└── hugo.toml               # Hugo 配置
```

## 故障排查

### 部署失败
1. 检查 GitHub Actions 日志: `Actions` 标签页
2. 确认所有 Secrets 配置正确
3. 测试 SSH 连接: `ssh -i ~/.ssh/blog_deploy deploy@服务器IP`

### 网站无法访问
1. 检查 nginx 状态: `systemctl status nginx`
2. 检查 nginx 日志: `tail -f /var/log/nginx/error.log`
3. 确认防火墙开放 80/443 端口: `ufw allow 'Nginx Full'`

### 内容未更新
1. 清除浏览器缓存
2. 检查服务器文件是否更新: `ls -la /var/www/blog`
