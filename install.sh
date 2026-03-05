#!/bin/bash

# install.sh
# 一键安装 planify skill 到当前工程目录
# 使用方法：
#   Linux/Mac: bash <(curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh)
#   Windows (Git Bash/WSL): bash <(curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh)
#   Windows (PowerShell): iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex

set -e

# 仓库信息
REPO="jayli/plan-kit"
BRANCH="${PLAN_KIT_BRANCH:-main}"

# 颜色输出
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
BOLD="\033[1m"
GRAY="\033[90m"
NC="\033[0m"

# 所有支持的配置目录
ALL_CONFIG_DIRS=(".claude" ".opencode" ".qwen" ".codex" ".gemini")

# 获取工具显示名称
get_tool_name() {
    case "$1" in
        .claude) echo "Claude Code" ;;
        .opencode) echo "OpenCode" ;;
        .qwen) echo "Qwen Qoder" ;;
        .codex) echo "OpenAI Codex" ;;
        .gemini) echo "Gemini CLI" ;;
        *) echo "$1" ;;
    esac
}

# 查找项目中的配置目录（包括局部和全局）
find_project_configs() {
    local current_dir="$(pwd)"
    local found_list=""

    # 1. 向上查找局部配置
    while [ "$current_dir" != "/" ] && [ "$current_dir" != "" ]; do
        for cfg in "${ALL_CONFIG_DIRS[@]}"; do
            if [ -d "$current_dir/$cfg" ]; then
                if [[ "$found_list" != *"$current_dir/$cfg"* ]]; then
                    [ -n "$found_list" ] && found_list="$found_list|"
                    found_list="${found_list}${current_dir}/$cfg"
                fi
            fi
        done
        local parent="$(dirname "$current_dir")"
        [ "$parent" = "$current_dir" ] && break
        current_dir="$parent"
    done

    # 2. 查找全局配置
    for cfg in "${ALL_CONFIG_DIRS[@]}"; do
        if [ -d "$HOME/$cfg" ]; then
            if [[ "$found_list" != *"$HOME/$cfg"* ]]; then
                [ -n "$found_list" ] && found_list="$found_list|"
                found_list="${found_list}${HOME}/$cfg"
            fi
        fi
    done

    printf '%s' "$found_list"
}

# 检查是否已安装
is_installed() {
    [ -f "$1/skills/planify/SKILL.md" ]
}

# 安装到指定目录
do_install() {
    local cfg_dir="$1"
    local cfg_name="$(basename "$cfg_dir")"
    local tool_name="$(get_tool_name "$cfg_name")"
    local target="$cfg_dir/skills/planify"

    echo ""
    if is_installed "$cfg_dir"; then
        printf "${CYAN}[%s] 检测到已安装的 planify skill${NC}\n" "$tool_name"
        echo "即将升级到最新版本..."
    else
        printf "${CYAN}[%s] 开始安装 planify skill...${NC}\n" "$tool_name"
    fi

    mkdir -p "$target"

    for file in SKILL.md example.md planify-template.md; do
        printf "  下载 %s...\n" "$file"
        curl -sSL "https://raw.githubusercontent.com/${REPO}/${BRANCH}/$cfg_name/skills/planify/${file}" -o "$target/$file"
    done

    if [ -f "$target/SKILL.md" ]; then
        printf "${GREEN}  ✅ 安装成功！${NC}\n"
        printf "     位置：%s\n" "$target"
    else
        printf "${RED}  ❌ 安装失败${NC}\n"
        exit 1
    fi
}

# 交互式菜单函数（支持多选）
# 参数：标题，选项数组（用 | 分隔）
# 返回：选中的索引，空格分隔
interactive_menu() {
    local title="$1"
    local multi_select="${2:-false}"
    shift 2
    local options=("$@")
    local count=${#options[@]}
    local cur=0
    local key=""

    # 隐藏光标并保存当前位置
    printf "\033[?25l\033[s"

    while true; do
        # 恢复到保存的位置并清除从光标到屏幕末尾的内容
        printf "\033[u\033[J"

        # 1. 渲染菜单
        echo ""
        echo -e "--- $title ---"
        echo -e "${GRAY}使用 ↑↓ 选择，Enter 确认，0 取消${NC}"
        echo ""

        for i in "${!options[@]}"; do
            if [[ $i -eq $cur ]]; then
                echo -e "${CYAN}  > ${options[$i]}${NC}"
            else
                echo -e "    ${options[$i]}"
            fi
        done

        # 2. 读取按键
        IFS= read -rsn1 -d '' key < /dev/tty 2>/dev/null || key=""

        # 处理转义序列 (方向键)
        if [[ "$key" == $'\e' ]]; then
            IFS= read -rsn2 -d '' key < /dev/tty 2>/dev/null || key=""
            # 去掉 [ 前缀
            key="${key#\[}"
        fi

        # 3. 逻辑判断
        case "$key" in
            "A") # 向上键
                ((cur--))
                [ $cur -lt 0 ] && cur=$((count - 1))
                ;;
            "B") # 向下键
                ((cur++))
                [ $cur -ge $count ] && cur=0
                ;;
            "" | $'\n' | $'\r') # Enter
                RESULT_INDICES=($cur)
                break
                ;;
            "0") # 取消
                RESULT_INDICES=()
                break
                ;;
        esac
    done

    # 恢复光标并换行
    printf "\033[?25h"
    echo ""
}

# 核心：确保从终端读取输入
# 此脚本必须在交互环境下运行
exec < /dev/tty

# ============ 主逻辑 ============

clear

printf "${BOLD}${CYAN}Planify Skill 安装程序${NC}\n"
echo ""
echo "正在检测当前项目的 AI 工具配置目录..."
echo ""

FOUND_DIRS="$(find_project_configs)"

if [ -n "$FOUND_DIRS" ]; then
    # 找到配置目录
    printf "${GREEN}检测到以下 AI 工具已配置：${NC}\n"
    echo ""

    # 将目录转换为数组并构建菜单项
    IFS='|' read -ra DIRS_ARR <<< "$FOUND_DIRS"
    MENU_ITEMS=()
    for dir in "${DIRS_ARR[@]}"; do
        [ -z "$dir" ] && continue
        dn="$(basename "$dir")"
        tn="$(get_tool_name "$dn")"
        if is_installed "$dir"; then
            MENU_ITEMS+=("$tn  ${GRAY}$dir${NC}  ${GREEN}[已安装]${NC}")
        else
            MENU_ITEMS+=("$tn  ${GRAY}$dir${NC}")
        fi
    done

    # 显示交互式菜单（单选）
    RESULT_INDICES=()
    interactive_menu "请选择要安装/升级的工具" "false" "${MENU_ITEMS[@]}"

    if [ ${#RESULT_INDICES[@]} -eq 0 ]; then
        printf "\n${RED}安装已取消${NC}\n"
        exit 0
    fi

    # 安装到选中的目录
    idx="${RESULT_INDICES[0]}"
    do_install "${DIRS_ARR[$idx]}"

else
    # 未找到配置目录
    printf "${YELLOW}⚠️  当前项目未检测到任何 AI 工具配置目录${NC}\n"
    echo ""
    echo "这表示当前项目尚未被任何 AI 工具初始化。"
    echo ""

    # 构建菜单项
    MENU_ITEMS=()
    for cfg in "${ALL_CONFIG_DIRS[@]}"; do
        tn="$(get_tool_name "$cfg")"
        MENU_ITEMS+=("$tn  ${GRAY}($cfg)${NC}")
    done

    printf "${CYAN}请选择要创建的配置目录：${NC}\n"

    # 显示交互式菜单（单选）
    RESULT_INDICES=()
    interactive_menu "请选择配置目录类型" "false" "${MENU_ITEMS[@]}"

    if [ ${#RESULT_INDICES[@]} -eq 0 ]; then
        printf "\n${RED}安装已取消${NC}\n"
        exit 0
    fi

    idx="${RESULT_INDICES[0]}"
    SELECTED_CONFIG="${ALL_CONFIG_DIRS[$idx]}"

    echo ""
    read -p "是否在当前目录创建 $SELECTED_CONFIG/skills/ 目录？[y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        do_install "$(pwd)/$SELECTED_CONFIG"
    else
        printf "${RED}安装已取消${NC}\n"
        exit 0
    fi
fi

echo ""
printf "${BOLD}使用方法:${NC}\n"
echo "  /planify <skill-name>  - 升级指定 skill 为 plan 驱动模式"
echo "  /planify               - 交互式选择要升级的 skill"
echo ""
