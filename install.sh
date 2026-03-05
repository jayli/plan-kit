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

# 颜色输出
if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    GREEN="\033[32m"
    RED="\033[31m"
    YELLOW="\033[33m"
    CYAN="\033[36m"
    BOLD="\033[1m"
    NC="\033[0m"
else
    GREEN=""
    RED=""
    YELLOW=""
    CYAN=""
    BOLD=""
    NC=""
fi

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
    local found_dirs=""

    # 从当前目录向上查找
    while [ "$current_dir" != "/" ] && [ -n "$current_dir" ]; do
        for config_dir in $CONFIG_DIRS; do
            if [ -d "$current_dir/$config_dir" ]; then
                if [ -n "$found_dirs" ]; then
                    found_dirs="$found_dirs|$current_dir/$config_dir"
                else
                    found_dirs="$current_dir/$config_dir"
                fi
            fi
        done
        local parent_dir="$(dirname "$current_dir")"
        [ "$parent_dir" = "$current_dir" ] && break
        current_dir="$parent_dir"
    done

    # 如果没找到，检查家目录
    if [ -z "$found_dirs" ]; then
        for config_dir in $CONFIG_DIRS; do
            if [ -d "$HOME/$config_dir" ]; then
                if [ -n "$found_dirs" ]; then
                    found_dirs="$found_dirs|$HOME/$config_dir"
                else
                    found_dirs="$HOME/$config_dir"
                fi
            fi
        done
    fi

    echo "$found_dirs"
}

# 使用 Python 实现交互式菜单（支持箭头键）
run_interactive_menu() {
    python3 - "$1" << 'PYTHON_SCRIPT'
import sys
import termios
import tty
import os

dirs_arg = sys.argv[1] if len(sys.argv) > 1 else ""
dirs = [d for d in dirs_arg.split('|') if d]

if not dirs:
    print("none")
    sys.exit(0)

# 检查 stdin 是否是终端
if not sys.stdin.isatty():
    # 非终端模式，直接返回第一个
    print(dirs[0])
    sys.exit(0)

# 终端设置
fd = sys.stdin.fileno()
old_settings = termios.tcgetattr(fd)

try:
    tty.setraw(fd)
    cursor = 0
    selected = set()

    def print_menu():
        sys.stdout.write("\033[H\033[J")
        print("使用 ↑↓ 选择，空格 选中/取消，Enter 确认")
        print("")
        for i, d in enumerate(dirs):
            name = os.path.basename(d)
            tool_map = {
                '.claude': 'Claude Code',
                '.opencode': 'OpenCode',
                '.qwen': 'Qwen Qoder',
                '.codex': 'OpenAI Codex',
                '.gemini': 'Gemini CLI'
            }
            tool = tool_map.get(name, name)
            if i == cursor:
                marker = "▶"
                if i in selected:
                    status = "[✓]"
                else:
                    status = "[ ]"
                print(f"  \033[36m{marker} {status}\033[0m {tool} ({d})")
            else:
                if i in selected:
                    status = "[✓]"
                else:
                    status = "[ ]"
                print(f"    {status} {tool} ({d})")
        print("")
        print("  [0] 取消安装")
        sys.stdout.flush()

    print_menu()

    while True:
        ch = sys.stdin.read(1)
        if ch == '\x1b':
            ch2 = sys.stdin.read(1)
            if ch2 == '[':
                ch3 = sys.stdin.read(1)
                if ch3 == 'A':
                    if cursor > 0:
                        cursor -= 1
                        print_menu()
                elif ch3 == 'B':
                    if cursor < len(dirs) - 1:
                        cursor += 1
                        print_menu()
        elif ch == ' ':
            if cursor in selected:
                selected.remove(cursor)
            else:
                selected.add(cursor)
            print_menu()
        elif ch == '\n' or ch == '\r':
            if selected:
                result = [dirs[i] for i in sorted(selected)]
                print('\n'.join(result))
                sys.stdout.flush()
                sys.exit(0)
            else:
                print(dirs[cursor])
                sys.stdout.flush()
                sys.exit(0)
        elif ch == '0':
            print("CANCEL")
            sys.stdout.flush()
            sys.exit(1)

finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
PYTHON_SCRIPT
}

# 使用 Python 显示创建目录菜单
run_create_menu() {
    python3 << 'PYTHON_SCRIPT'
import sys
import termios
import tty

options = [
    (".claude", "Claude Code"),
    (".opencode", "OpenCode"),
    (".qwen", "Qwen Qoder"),
    (".codex", "OpenAI Codex"),
    (".gemini", "Gemini CLI")
]

# 检查 stdin 是否是终端
if not sys.stdin.isatty():
    print(".claude")
    sys.exit(0)

fd = sys.stdin.fileno()
old_settings = termios.tcgetattr(fd)

try:
    tty.setraw(fd)
    cursor = 0

    def print_menu():
        sys.stdout.write("\033[H\033[J")
        print("使用 ↑↓ 选择，Enter 确认")
        print("")
        for i, (opt, name) in enumerate(options):
            if i == cursor:
                print(f"  \033[36m▶ {name} ({opt})\033[0m")
            else:
                print(f"    {name} ({opt})")
        print("")
        print("  [0] 取消安装")
        sys.stdout.flush()

    print_menu()

    while True:
        ch = sys.stdin.read(1)
        if ch == '\x1b':
            ch2 = sys.stdin.read(1)
            if ch2 == '[':
                ch3 = sys.stdin.read(1)
                if ch3 == 'A' and cursor > 0:
                    cursor -= 1
                    print_menu()
                elif ch3 == 'B' and cursor < len(options) - 1:
                    cursor += 1
                    print_menu()
        elif ch == '\n' or ch == '\r':
            print(options[cursor][0])
            sys.stdout.flush()
            sys.exit(0)
        elif ch == '0':
            sys.exit(1)

finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
PYTHON_SCRIPT
}

# 主逻辑
echo "${CYAN}${BOLD}Planify Skill 安装程序${NC}"
echo ""
echo "正在检测 AI 工具配置目录..."
echo ""

FOUND_DIRS=$(find_existing_config_dirs)

# 将找到的目录转换为数组
IFS='|' read -ra FOUND_DIRS_ARRAY <<< "$FOUND_DIRS"

SELECTED_DIRS=()

if [ -n "$FOUND_DIRS" ] && [ "${#FOUND_DIRS_ARRAY[@]}" -gt 1 ]; then
    echo "${CYAN}发现多个 AI 工具配置目录：${NC}"
    echo ""

    sleep 0.5

    MENU_OUTPUT=$(run_interactive_menu "$FOUND_DIRS" || echo "CANCEL")

    if [ "$MENU_OUTPUT" = "CANCEL" ] || [ "$MENU_OUTPUT" = "none" ] || [ -z "$MENU_OUTPUT" ]; then
        echo "${RED}安装已取消${NC}"
        exit 1
    fi

    while IFS= read -r line; do
        [ -n "$line" ] && SELECTED_DIRS+=("$line")
    done <<< "$MENU_OUTPUT"

elif [ -n "$FOUND_DIRS" ]; then
    SELECTED_DIRS=("$FOUND_DIRS")
    echo "${CYAN}找到配置目录：${SELECTED_DIRS[0]}${NC}"
    echo ""
else
    echo "${YELLOW}⚠️  未找到任何 AI 工具配置目录${NC}"
    echo ""
    echo "支持的工具：Claude Code, OpenCode, Qwen Qoder, OpenAI Codex, Gemini CLI"
    echo ""

    SELECTED_CONFIG=$(run_create_menu || echo "")

    if [ -z "$SELECTED_CONFIG" ]; then
        echo "${RED}安装已取消${NC}"
        exit 1
    fi

    read -p "是否在当前目录创建 $SELECTED_CONFIG/skills/ 目录？[y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SELECTED_DIRS=("$(pwd)/$SELECTED_CONFIG")
    else
        echo "${RED}安装已取消${NC}"
        exit 1
    fi
fi

# 安装到每个选中的目录
for CONFIG_DIR in "${SELECTED_DIRS[@]}"; do
    CONFIG_NAME=$(basename "$CONFIG_DIR")
    TOOL_DISPLAY=$(get_tool_display_name "$CONFIG_NAME")
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

    FILES="SKILL.md example.md planify-template.md"

    for file in $FILES; do
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
