# install.ps1
# 一键安装 planify skill 到当前工程目录 (Windows PowerShell)
# 使用方法：iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex

$ErrorActionPreference = "Stop"

# 仓库信息
$REPO = "jayli/plan-kit"
$BRANCH = if ($env:PLAN_KIT_BRANCH) { $env:PLAN_KIT_BRANCH } else { "main" }

# 所有支持的配置目录
$ALL_CONFIG_DIRS = @(".claude", ".opencode", ".qwen", ".codex", ".gemini")

# 工具名称映射
$TOOL_NAMES = @{
    ".claude" = "Claude Code"
    ".opencode" = "OpenCode"
    ".qwen" = "Qwen Qoder"
    ".codex" = "OpenAI Codex"
    ".gemini" = "Gemini CLI"
}

function Get-ToolName {
    param([string]$dir)
    return $TOOL_NAMES[$dir] ?? $dir
}

# 查找项目中的配置目录
function Find-ProjectConfigs {
    $currentDir = Get-Location
    $found = @()

    # 1. 向上查找局部配置
    $tempDir = $currentDir
    while ($tempDir -ne $null) {
        foreach ($cfg in $ALL_CONFIG_DIRS) {
            $testPath = Join-Path $tempDir.Path $cfg
            if (Test-Path $testPath) {
                if ($found -notcontains $testPath) {
                    $found += $testPath
                }
            }
        }
        $tempDir = $tempDir.Parent
    }

    # 2. 查找全局配置
    $homeDir = $env:USERPROFILE
    if ($IsMacOS -or $IsLinux) {
        $homeDir = $env:HOME
    }

    foreach ($cfg in $ALL_CONFIG_DIRS) {
        $testPath = Join-Path $homeDir $cfg
        if (Test-Path $testPath) {
            if ($found -notcontains $testPath) {
                $found += $testPath
            }
        }
    }

    return $found
}

# 检查是否已安装
function Is-Installed {
    param([string]$cfgDir)
    return (Test-Path (Join-Path $cfgDir "skills/planify/SKILL.md"))
}

# 安装到指定目录
function Do-Install {
    param([string]$cfgDir)

    $cfgName = Split-Path $cfgDir -Leaf
    $toolName = Get-ToolName -dir $cfgName
    $target = Join-Path $cfgDir "skills/planify"

    Write-Host ""
    if (Is-Installed -cfgDir $cfgDir) {
        Write-Host "[$toolName] 检测到已安装的 planify skill" -ForegroundColor Yellow
        Write-Host "即将升级到最新版本..."
    } else {
        Write-Host "[$toolName] 开始安装 planify skill..." -ForegroundColor Cyan
    }

    if (-not (Test-Path (Join-Path $cfgDir "skills"))) {
        New-Item -ItemType Directory -Path (Join-Path $cfgDir "skills") | Out-Null
    }
    New-Item -ItemType Directory -Path $target -Force | Out-Null

    $FILES = @("SKILL.md", "example.md", "planify-template.md")

    foreach ($file in $FILES) {
        Write-Host "  下载 $file..."
        $url = "https://raw.githubusercontent.com/$REPO/$BRANCH/$cfgName/skills/planify/$file"
        try {
            Invoke-RestMethod -Uri $url -OutFile (Join-Path $target $file) -ErrorAction Stop
        } catch {
            Write-Host "  下载失败：$_" -ForegroundColor Red
            continue
        }
    }

    if (Test-Path (Join-Path $target "SKILL.md")) {
        Write-Host "  ✅ 安装成功！" -ForegroundColor Green
        Write-Host "     位置：$target"
    } else {
        Write-Host "  ❌ 安装失败" -ForegroundColor Red
        exit 1
    }
}

# 交互式菜单（支持多选）
function Show-InteractiveMenu {
    param(
        [string[]]$Items,
        [switch]$MultiSelect,
        [ref]$SelectedIndices
    )

    $cursor = 0
    $selected = @{}
    $host.UI.RawCursorVisible = $false

    function Draw-Menu {
        Clear-Host

        if ($MultiSelect) {
            Write-Host "使用 ↑↓ 选择，空格 选中/取消，Enter 确认" -ForegroundColor Gray
        } else {
            Write-Host "使用 ↑↓ 选择，Enter 确认" -ForegroundColor Gray
        }
        Write-Host "输入 0 取消安装" -ForegroundColor Gray
        Write-Host ""

        for ($i = 0; $i -lt $Items.Count; $i++) {
            $item = $Items[$i]

            if ($i -eq $cursor) {
                Write-Host " ▶ " -NoNewline -ForegroundColor Cyan
            } else {
                Write-Host "   " -NoNewline
            }

            if ($MultiSelect -and $selected.ContainsKey($i)) {
                Write-Host "[✓] " -NoNewline -ForegroundColor Green
            } elseif ($MultiSelect) {
                Write-Host "[ ] " -NoNewline
            }

            Write-Host $item
        }
        Write-Host ""
    }

    Draw-Menu

    while ($true) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 { # Up
                if ($cursor -gt 0) {
                    $cursor--
                    Draw-Menu
                }
            }
            40 { # Down
                if ($cursor -lt ($Items.Count - 1)) {
                    $cursor++
                    Draw-Menu
                }
            }
            32 { # Space
                if ($MultiSelect) {
                    if ($selected.ContainsKey($cursor)) {
                        $selected.Remove($cursor)
                    } else {
                        $selected[$cursor] = $true
                    }
                    Draw-Menu
                }
            }
            13 { # Enter
                $host.UI.RawCursorVisible = $true

                if ($MultiSelect) {
                    if ($selected.Count -eq 0) {
                        $SelectedIndices.Value = @($cursor)
                    } else {
                        $SelectedIndices.Value = @($selected.Keys | Sort-Object | ForEach-Object { $_ })
                    }
                } else {
                    $SelectedIndices.Value = @($cursor)
                }
                return $true
            }
            48 { # 0
                $host.UI.RawCursorVisible = $true
                return $false
            }
        }
    }
}

# ============ 主逻辑 ============

Clear-Host

Write-Host "Planify Skill 安装程序" -ForegroundColor Cyan
Write-Host ""
Write-Host "正在检测当前项目的 AI 工具配置目录..."
Write-Host ""

$FOUND_DIRS = Find-ProjectConfigs

if ($FOUND_DIRS.Count -gt 0) {
    # 找到配置目录
    Write-Host "检测到以下 AI 工具已配置：" -ForegroundColor Green
    Write-Host ""

    # 构建菜单项
    $MENU_ITEMS = @()
    foreach ($dir in $FOUND_DIRS) {
        $dn = Split-Path $dir -Leaf
        $tn = Get-ToolName -dir $dn
        if (Is-Installed -cfgDir $dir) {
            $MENU_ITEMS += "$tn  $dir  [已安装]"
        } else {
            $MENU_ITEMS += "$tn  $dir"
        }
    }

    # 显示交互式菜单
    $selectedIndices = @()
    if (Show-InteractiveMenu -Items $MENU_ITEMS -SelectedIndices ([ref]$selectedIndices)) {
        # 安装到选中的目录
        $idx = $selectedIndices[0]
        Do-Install -cfgDir $FOUND_DIRS[$idx]
    } else {
        Write-Host "安装已取消" -ForegroundColor Red
        exit 0
    }

} else {
    # 未找到配置目录
    Write-Host "⚠️  当前项目未检测到任何 AI 工具配置目录" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "这表示当前项目尚未被任何 AI 工具初始化。"
    Write-Host ""

    # 构建菜单项
    $MENU_ITEMS = @()
    foreach ($cfg in $ALL_CONFIG_DIRS) {
        $tn = Get-ToolName -dir $cfg
        $MENU_ITEMS += "$tn  ($cfg)"
    }

    Write-Host "请选择要创建的配置目录：" -ForegroundColor Cyan
    Write-Host ""

    # 显示交互式菜单（单选）
    $selectedIndex = @()
    if (Show-InteractiveMenu -Items $MENU_ITEMS -SelectedIndices ([ref]$selectedIndex)) {
        $idx = $selectedIndex[0]
        $SELECTED_CONFIG = $ALL_CONFIG_DIRS[$idx]

        Write-Host ""
        $response = Read-Host "是否在当前目录创建 $SELECTED_CONFIG/skills/ 目录？[y/N]"
        Write-Host ""

        if ($response -match '^[Yy]$') {
            Do-Install -cfgDir (Join-Path (Get-Location) $SELECTED_CONFIG)
        } else {
            Write-Host "安装已取消" -ForegroundColor Red
            exit 0
        }
    } else {
        Write-Host "安装已取消" -ForegroundColor Red
        exit 0
    }
}

Write-Host ""
Write-Host "使用方法:" -ForegroundColor Cyan
Write-Host "  /planify <skill-name>  - 升级指定 skill 为 plan 驱动模式"
Write-Host "  /planify               - 交互式选择要升级的 skill"
Write-Host ""
