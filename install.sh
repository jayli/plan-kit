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

# 查找项目中的配置目录
find_project_configs() {
    local current_dir="$(pwd)"
    local found=()

    while [ "$current_dir" != "/" ] && [ "$current_dir" != "" ]; do
        for cfg in "${ALL_CONFIG_DIRS[@]}"; do
            [ -d "$current_dir/$cfg" ] && found+=("$current_dir/$cfg")
        done
        local parent="$(dirname "$current_dir")"
        [ "$parent" = "$current_dir" ] && break
        current_dir="$parent"
    done

    printf '%s\n' "${found[@]}"
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

# 交互式菜单（支持多选）
# 返回选中的索引，空格分隔
interactive_menu() {
    local -n items_ref=$1
    local -n result_ref=$2
    local multi=${3:-true}

    local cursor=0
    local -A selected

    # 保存终端设置
    if [ -t 0 ]; then
        old_settings=$(stty -g 2>/dev/null || echo "")
        trap 'stty "$old_settings" 2>/dev/null' EXIT
    fi

    # 隐藏光标
    printf "\033[?25l"

    local function draw() {
        # 清屏并移动光标到顶部
        printf "\033[H\033[J"

        if [ "$multi" = "true" ]; then
            printf "${BOLD}使用 ↑↓ 选择，空格 选中/取消，Enter 确认${NC}\n"
        else
            printf "${BOLD}使用 ↑↓ 选择，Enter 确认${NC}\n"
        fi
        printf "${GRAY}输入 0 取消安装${NC}\n"
        echo ""

        for i in "${!items_ref[@]}"; do
            local item="${items_ref[$i]}"
            local prefix="   "

            if [ $i -eq $cursor ]; then
                prefix="${CYAN} ▶ ${NC}"
            fi

            if [ "$multi" = "true" ]; then
                if [ -n "${selected[$i]}" ]; then
                    printf "${prefix}${GREEN}[✓]${NC} %s\n" "$item"
                else
                    printf "${prefix}[ ] %s\n" "$item"
                fi
            else
                printf "${prefix}%s\n" "$item"
            fi
        done
        echo ""
    }

    draw

    while true; do
        # 从 /dev/tty 读取，绕过 stdin 重定向
        if [ -t 0 ]; then
            read -n1 -s key < /dev/tty 2>/dev/null || true
        else
            read -n1 -s key 2>/dev/null || true
        fi

        case "$key" in
            # ESC 序列 (箭头键)
            $'\x1b')
                read -n2 -s rest 2>/dev/null || true
                case "$rest" in
                    '[A') [ $cursor -gt 0 ] && ((cursor--)) && draw ;;  # 上
                    '[B') [ $cursor -lt $((${#items_ref[@]}-1)) ] && ((cursor++)) && draw ;;  # 下
                esac
                ;;
            ' ')  # 空格 - 多选切换
                if [ "$multi" = "true" ]; then
                    if [ -n "${selected[$cursor]}" ]; then
                        unset selected[$cursor]
                    else
                        selected[$cursor]=1
                    fi
                    draw
                fi
                ;;
            ''|$'\n')  # Enter - 确认
                printf "\033[?25h"  # 显示光标
                printf "\n"

                if [ "$multi" = "true" ]; then
                    if [ ${#selected[@]} -gt 0 ]; then
                        result_ref=("${!selected[@]}")
                        return 0
                    else
                        # 未选择时默认当前项
                        result_ref=($cursor)
                        return 0
                    fi
                else
                    result_ref=($cursor)
                    return 0
                fi
                ;;
            '0')  # 0 - 取消
                printf "\033[?25h"
                printf "\n"
                return 1
                ;;
        esac
    done
}

# 显示确认菜单并返回选中的索引
show_menu() {
    local -n menu_items=$1
    local -n menu_result=$2
    local multi=${3:-true}

    # 切换到备用屏幕
    printf "\033[?1049h"
    printf "\033[H"

    local result
    if interactive_menu menu_items result "$multi"; then
        menu_result=("${result[@]}")
        # 恢复主屏幕
        printf "\033[?1049l"
        return 0
    else
        # 恢复主屏幕
        printf "\033[?1049l"
        return 1
    fi
}

# ============ 主逻辑 ============

clear

printf "${BOLD}${CYAN}Planify Skill 安装程序${NC}\n"
echo ""
echo "正在检测当前项目的 AI 工具配置目录..."
echo ""

# 查找配置目录
mapfile -t FOUND_DIRS < <(find_project_configs)

if [ ${#FOUND_DIRS[@]} -gt 0 ]; then
    # 找到配置目录
    printf "${GREEN}检测到以下 AI 工具已配置：${NC}\n"
    echo ""

    # 构建菜单项
    MENU_ITEMS=()
    for dir in "${FOUND_DIRS[@]}"; do
        dn="$(basename "$dir")"
        tn="$(get_tool_name "$dn")"
        if is_installed "$dir"; then
            MENU_ITEMS+=("$tn  ${GRAY}$dir${NC}  ${GREEN}[已安装]${NC}")
        else
            MENU_ITEMS+=("$tn  ${GRAY}$dir${NC}")
        fi
    done

    # 显示交互式菜单
    if show_menu MENU_ITEMS SELECTED_INDICES true; then
        # 安装到选中的目录
        for idx in "${SELECTED_INDICES[@]}"; do
            do_install "${FOUND_DIRS[$idx]}"
        done
    else
        printf "${RED}安装已取消${NC}\n"
        exit 0
    fi

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
    echo ""

    # 显示交互式菜单（单选）
    if show_menu MENU_ITEMS SELECTED_INDEX false; then
        idx="${SELECTED_INDEX[0]}"
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
