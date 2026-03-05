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

# 颜色输出（兼容不支持颜色的终端）
if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    GREEN="\033[32m"
    RED="\033[31m"
    YELLOW="\033[33m"
    CYAN="\033[36m"
    NC="\033[0m" # No Color
else
    GREEN=""
    RED=""
    YELLOW=""
    CYAN=""
    NC=""
fi

# 向上查找 .claude 目录
find_claude_dir() {
    local current_dir="$(pwd)"
    local claude_dir=""

    # 从当前目录向上查找，直到根目录
    while [ "$current_dir" != "/" ] && [ -n "$current_dir" ]; do
        if [ -d "$current_dir/.claude" ]; then
            claude_dir="$current_dir/.claude"
            break
        fi
        local parent_dir="$(dirname "$current_dir")"
        # 如果父目录和当前目录相同，说明已经到根目录了
        if [ "$parent_dir" = "$current_dir" ]; then
            break
        fi
        current_dir="$parent_dir"
    done

    # 如果没找到，检查家目录
    if [ -z "$claude_dir" ] && [ -d "$HOME/.claude" ]; then
        claude_dir="$HOME/.claude"
    fi

    echo "$claude_dir"
}

# 查找 .claude 目录
CLAUDE_DIR=$(find_claude_dir)

if [ -n "$CLAUDE_DIR" ] && [ -d "$CLAUDE_DIR" ]; then
    echo "${CYAN}找到 .claude 目录：$CLAUDE_DIR${NC}"
    echo ""
    TARGET_DIR="$CLAUDE_DIR/skills"
else
    echo "${YELLOW}⚠️  未找到 .claude 目录${NC}"
    echo ""
    echo "当前项目尚未被 Claude 初始化。"
    echo ""
    read -p "是否在当前目录创建 .claude/skills/ 目录？[y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        TARGET_DIR="$(pwd)/.claude/skills"
        echo "${CYAN}将在当前目录创建 .claude/skills/...${NC}"
    else
        echo "${RED}安装已取消${NC}"
        exit 1
    fi
fi

# 检查是否已安装
if [ -f "$TARGET_DIR/planify/SKILL.md" ]; then
    echo "检测到已安装的 planify skill"
    echo "即将升级到最新版本..."
    echo ""
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
