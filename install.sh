#!/bin/bash

# install.sh
# 一键安装 planify skill 到当前工程目录
# 使用方法：
#   Linux/Mac: bash <(curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh)
#   Windows (Git Bash/WSL): bash <(curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh)
#   Windows (PowerShell): iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex

set -e

# 颜色输出
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
BOLD="\033[1m"
NC="\033[0m"

# 仓库信息
REPO="jayli/plan-kit"
BRANCH="${PLAN_KIT_BRANCH:-main}"

# 支持的配置目录列表
CONFIG_DIRS=".claude .opencode .qwen .codex .gemini"

# 获取工具显示名称
get_tool_display_name() {
    local dir="$1"
    case "$dir" in
        .claude) echo "Claude Code" ;;
        .opencode) echo "OpenCode" ;;
        .qwen) echo "Qwen Qoder" ;;
        .codex) echo "OpenAI Codex" ;;
        .gemini) echo "Gemini CLI" ;;
        *) echo "$dir" ;;
    esac
}

# 向上查找所有存在的配置目录
find_existing_config_dirs() {
    local current_dir="$(pwd)"
    local found_list=""

    while [ "$current_dir" != "/" ] && [ "$current_dir" != "" ]; do
        for config_dir in $CONFIG_DIRS; do
            if [ -d "$current_dir/$config_dir" ]; then
                if [ -n "$found_list" ]; then
                    found_list="$found_list
$current_dir/$config_dir"
                else
                    found_list="$current_dir/$config_dir"
                fi
            fi
        done
        local parent_dir="$(dirname "$current_dir")"
        [ "$parent_dir" = "$current_dir" ] && break
        current_dir="$parent_dir"
    done

    if [ -z "$found_list" ]; then
        for config_dir in $CONFIG_DIRS; do
            if [ -d "$HOME/$config_dir" ]; then
                if [ -n "$found_list" ]; then
                    found_list="$found_list
$HOME/$config_dir"
                else
                    found_list="$HOME/$config_dir"
                fi
            fi
        done
    fi

    printf '%s' "$found_list"
}

# 主逻辑
echo "${CYAN}${BOLD}Planify Skill 安装程序${NC}"
echo ""
echo "正在检测 AI 工具配置目录..."
echo ""

FOUND_DIRS="$(find_existing_config_dirs)"

if [ -z "$FOUND_DIRS" ]; then
    # 未找到任何配置目录
    echo "${YELLOW}⚠️  未找到任何 AI 工具配置目录${NC}"
    echo ""
    echo "支持的工具：Claude Code, OpenCode, Qwen Qoder, OpenAI Codex, Gemini CLI"
    echo ""
    echo "请选择要创建的配置目录类型："
    echo "  1) Claude Code (.claude/)"
    echo "  2) OpenCode (.opencode/)"
    echo "  3) Qwen Qoder (.qwen/)"
    echo "  4) OpenAI Codex (.codex/)"
    echo "  5) Gemini CLI (.gemini/)"
    echo "  0) 取消安装"
    echo ""

    read -p "请选择 [1-5]: " selection
    echo ""

    case "$selection" in
        1) SELECTED_CONFIG=".claude" ;;
        2) SELECTED_CONFIG=".opencode" ;;
        3) SELECTED_CONFIG=".qwen" ;;
        4) SELECTED_CONFIG=".codex" ;;
        5) SELECTED_CONFIG=".gemini" ;;
        *)
            echo "${RED}无效选择，安装已取消${NC}"
            exit 1
            ;;
    esac

    read -p "是否在当前目录创建 $SELECTED_CONFIG/skills/ 目录？[y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SELECTED_DIRS="$(pwd)/$SELECTED_CONFIG"
    else
        echo "${RED}安装已取消${NC}"
        exit 1
    fi

else
    # 将找到的目录转换为数组
    SELECTED_DIRS=""
    dir_count=0

    while IFS= read -r dir; do
        [ -z "$dir" ] && continue
        dir_count=$((dir_count + 1))
        if [ $dir_count -eq 1 ]; then
            SELECTED_DIRS="$dir"
        else
            SELECTED_DIRS="$SELECTED_DIRS
$dir"
        fi
    done <<< "$FOUND_DIRS"

    if [ $dir_count -eq 1 ]; then
        echo "${CYAN}找到配置目录：$SELECTED_DIRS${NC}"
        echo ""
    else
        echo "${CYAN}发现多个 AI 工具配置目录：${NC}"
        echo ""
        echo "$SELECTED_DIRS" | while IFS= read -r d; do
            [ -z "$d" ] && continue
            dn="$(basename "$d")"
            tn="$(get_tool_display_name "$dn")"
            echo "  - $tn ($d)"
        done
        echo ""
        echo "将安装到所有检测到的目录"
        echo ""
    fi
fi

# 安装到每个选中的目录
echo "$SELECTED_DIRS" | while IFS= read -r CONFIG_DIR; do
    [ -z "$CONFIG_DIR" ] && continue

    CONFIG_NAME="$(basename "$CONFIG_DIR")"
    TOOL_DISPLAY="$(get_tool_display_name "$CONFIG_NAME")"
    TARGET_DIR="$CONFIG_DIR/skills"

    if [ -f "$TARGET_DIR/planify/SKILL.md" ]; then
        echo ""
        echo "${CYAN}[$TOOL_DISPLAY] 检测到已安装的 planify skill${NC}"
        echo "即将升级到最新版本..."
    else
        echo ""
        echo "${CYAN}[$TOOL_DISPLAY] 开始安装 planify skill...${NC}"
    fi

    mkdir -p "$TARGET_DIR/planify"

    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl -sSL"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget -qO-"
    else
        echo "${RED}错误：找不到 curl 或 wget，请安装其中一个下载工具${NC}"
        exit 1
    fi

    for file in SKILL.md example.md planify-template.md; do
        url="https://raw.githubusercontent.com/${REPO}/${BRANCH}/$CONFIG_NAME/skills/planify/${file}"
        echo "  下载 ${file}..."
        $DOWNLOAD_CMD "$url" -o "$TARGET_DIR/planify/${file}"
    done

    if [ -f "$TARGET_DIR/planify/SKILL.md" ]; then
        echo -e "${GREEN}  ✅ planify skill 安装成功！${NC}"
        echo "     安装位置：$TARGET_DIR/planify"
    else
        echo "${RED}  ❌ 安装失败${NC}"
        exit 1
    fi
done

echo ""
echo "使用方法:"
echo "  /planify <skill-name>  - 升级指定 skill 为 plan 驱动模式"
echo "  /planify               - 交互式选择要升级的 skill"
