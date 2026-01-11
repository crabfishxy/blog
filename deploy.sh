#!/bin/bash
#
# 一键部署脚本 - 提交代码并触发 GitHub Actions 自动部署
#
# 使用方法:
#   ./deploy.sh "提交信息"
#   ./deploy.sh                  # 使用默认提交信息
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认提交信息
COMMIT_MSG="${1:-Update blog content $(date '+%Y-%m-%d %H:%M:%S')}"

echo -e "${BLUE}🚀 开始部署博客...${NC}"
echo ""

# 检查是否有改动
if [[ -z $(git status -s) ]]; then
    echo -e "${YELLOW}⚠️  没有检测到文件改动${NC}"
    echo -e "${YELLOW}是否仍要触发部署? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${RED}已取消部署${NC}"
        exit 0
    fi
    # 创建空提交来触发部署
    git commit --allow-empty -m "Trigger deployment: $COMMIT_MSG"
else
    # 添加所有改动
    echo -e "${GREEN}📝 添加文件改动...${NC}"
    git add -A
    
    # 显示将要提交的改动
    echo -e "${BLUE}改动文件:${NC}"
    git status -s
    echo ""
    
    # 提交改动
    echo -e "${GREEN}💾 提交改动...${NC}"
    git commit -m "$COMMIT_MSG"
fi

# 推送到 GitHub
echo -e "${GREEN}📤 推送到 GitHub...${NC}"
git push origin main

echo ""
echo -e "${GREEN}✅ 代码已推送！GitHub Actions 正在构建并部署...${NC}"
echo ""
echo -e "${BLUE}📊 查看部署状态:${NC}"
echo -e "   https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
echo ""
echo -e "${YELLOW}💡 提示: 部署通常需要 1-2 分钟完成${NC}"
