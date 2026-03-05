#!/bin/bash

# install.sh
# 一键安装 planify skill 到当前工程目录
# 使用方法：
#   Linux/Mac: curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh | sh
#   Windows (PowerShell): iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex
#   Windows (Git Bash/WSL): curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh | sh

set -e

# 仓库信息
REPO="jayli/plan-kit"
BRANCH="${PLAN_KIT_BRANCH:-main}"

# 目标目录：当前工程的 .claude/skills
TARGET_DIR="$(pwd)/.claude/skills"

# 颜色输出（兼容不支持颜色的终端）
if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    GREEN="\033[32m"
    RED="\033[31m"
    YELLOW="\033[33m"
    NC="\033[0m" # No Color
else
    GREEN=""
    RED=""
    YELLOW=""
    NC=""
fi

echo "🚀 开始安装 planify skill..."

# 创建目标目录（如果不存在）
mkdir -p "$TARGET_DIR/planify"

# 检测下载工具
if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl -sSL"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget -qO-"
else
    echo "${RED}错误：找不到 curl 或 wget，请安装其中一个下载工具${NC}"
    exit 1
fi

# 定义要下载的文件
FILES=("SKILL.md" "example.md" "planify-template.md")

# 从 GitHub 下载每个文件
for file in "${FILES[@]}"; do
    url="https://raw.githubusercontent.com/${REPO}/${BRANCH}/.claude/skills/planify/${file}"
    echo "下载 ${file}..."
    $DOWNLOAD_CMD "$url" -o "$TARGET_DIR/planify/${file}"
done

# 验证安装
if [ -f "$TARGET_DIR/planify/SKILL.md" ]; then
    echo ""
    echo "${GREEN}✅ planify skill 安装成功！${NC}"
    echo ""
    echo "安装位置：$TARGET_DIR/planify"
    echo ""
    echo "使用方法:"
    echo "  /planify <skill-name>  - 升级指定 skill 为 plan 驱动模式"
    echo "  /planify               - 交互式选择要升级的 skill"
else
    echo "${RED}❌ 安装失败${NC}"
    exit 1
fi
