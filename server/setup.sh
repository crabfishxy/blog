#!/bin/bash
#
# 服务器初始化脚本
# 在你的服务器上运行此脚本来配置 nginx 和部署目录
#
# 使用方法: 
#   1. 将此脚本上传到服务器
#   2. 修改下面的配置变量
#   3. sudo bash setup.sh
#

set -e

#=============================================================================
# 配置区域 - 请根据你的实际情况修改
#=============================================================================
DOMAIN="your-domain.com"        # 你的域名，如果没有可以用 IP
DEPLOY_USER="deploy"            # 用于部署的用户名
DEPLOY_PATH="/var/www/blog"     # 网站文件存放路径
#=============================================================================

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 开始配置服务器...${NC}"

# 1. 安装 nginx (如果未安装)
if ! command -v nginx &> /dev/null; then
    echo -e "${GREEN}📦 安装 nginx...${NC}"
    apt-get update
    apt-get install -y nginx
fi

# 2. 创建部署用户 (如果不存在)
if ! id "$DEPLOY_USER" &>/dev/null; then
    echo -e "${GREEN}👤 创建部署用户: $DEPLOY_USER${NC}"
    useradd -m -s /bin/bash "$DEPLOY_USER"
fi

# 3. 创建网站目录
echo -e "${GREEN}📁 创建网站目录: $DEPLOY_PATH${NC}"
mkdir -p "$DEPLOY_PATH"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_PATH"

# 4. 创建 nginx 配置
echo -e "${GREEN}⚙️  配置 nginx...${NC}"
cat > /etc/nginx/sites-available/blog << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    
    root $DEPLOY_PATH;
    index index.html;
    
    # 启用 gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_min_length 1000;
    
    # 静态文件缓存
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # 主要路由
    location / {
        try_files \$uri \$uri/ \$uri.html =404;
    }
    
    # 自定义 404 页面
    error_page 404 /404.html;
}
EOF

# 5. 启用站点
ln -sf /etc/nginx/sites-available/blog /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default  # 移除默认站点

# 6. 测试并重启 nginx
echo -e "${GREEN}🔄 重启 nginx...${NC}"
nginx -t
systemctl restart nginx
systemctl enable nginx

# 7. 设置 SSH 密钥目录
SSH_DIR="/home/$DEPLOY_USER/.ssh"
mkdir -p "$SSH_DIR"
touch "$SSH_DIR/authorized_keys"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"

echo ""
echo -e "${GREEN}✅ 服务器配置完成！${NC}"
echo ""
echo -e "${BLUE}📋 下一步操作:${NC}"
echo ""
echo "1. 在你的本地机器生成 SSH 密钥对 (如果没有的话):"
echo "   ssh-keygen -t ed25519 -C \"github-actions-deploy\""
echo ""
echo "2. 将公钥添加到服务器:"
echo "   cat ~/.ssh/id_ed25519.pub | ssh root@YOUR_SERVER \"cat >> /home/$DEPLOY_USER/.ssh/authorized_keys\""
echo ""
echo "3. 在 GitHub 仓库设置以下 Secrets (Settings → Secrets and variables → Actions):"
echo "   - SSH_PRIVATE_KEY: 你的私钥内容 (cat ~/.ssh/id_ed25519)"
echo "   - SERVER_HOST: 服务器 IP 或域名"
echo "   - SERVER_USER: $DEPLOY_USER"
echo "   - SERVER_PORT: 22 (或你的 SSH 端口)"
echo "   - DEPLOY_PATH: $DEPLOY_PATH"
echo ""
echo -e "${BLUE}🔐 可选: 配置 HTTPS (推荐使用 Let's Encrypt):${NC}"
echo "   apt install certbot python3-certbot-nginx"
echo "   certbot --nginx -d $DOMAIN"
