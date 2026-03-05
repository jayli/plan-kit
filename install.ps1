# install.ps1
# 一键安装 planify skill 到当前工程目录 (Windows PowerShell)
# 使用方法：iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex

$ErrorActionPreference = "Stop"

# 仓库信息
$REPO = "jayli/plan-kit"
$BRANCH = if ($env:PLAN_KIT_BRANCH) { $env:PLAN_KIT_BRANCH } else { "main" }

# 所有支持的配置目录
$ALL_CONFIG_DIRS = @(".claude", ".opencode", ".qwen", ".codex", ".gemini", ".antigravity", ".windsurf", ".roocode", ".kilocode", ".codebuddy", ".qoder")

# 工具名称映射
$TOOL_NAMES = @{
    ".claude" = "Claude Code"
    ".opencode" = "OpenCode"
    ".qwen" = "Qwen Code"
    ".codex" = "OpenAI Codex"
    ".gemini" = "Gemini CLI"
    ".antigravity" = "Antigravity"
    ".windsurf" = "Windsurf"
    ".roocode" = "Roo Code"
    ".kilocode" = "Kilo Code"
    ".codebuddy" = "CodeBuddy CLI"
    ".qoder" = "Qoder-CLI"
}

function Get-ToolName {
    param([string]$dir)
    return $TOOL_NAMES[$dir] ?? $dir
}

# 判断是否为中文环境
function Test-ChineseLanguage {
    # 检查 $PSUICulture
    if ($PSUICulture -like "zh-*") {
        return $true
    }
    # 检查 Get-UICulture
    $culture = Get-UICulture
    if ($culture.Name -like "zh-*") {
        return $true
    }
    return $false
}

# 根据语言获取文本
function Get-Text {
    param([string]$Key)

    if (Test-ChineseLanguage) {
        switch ($Key) {
            "installer_title" { return "Planify Skill 安装程序" }
            "detecting_config" { return "正在检测当前项目的 AI 工具配置目录..." }
            "menu_title" { return "请选择要安装/升级的工具" }
            "menu_hint_select" { return "使用 ↑↓ 选择，Enter 确认" }
            "menu_hint_multi" { return "使用 ↑↓ 选择，空格 选中/取消，Enter 确认" }
            "menu_hint_cancel" { return "输入 0 取消安装" }
            "installed" { return "[已安装]" }
            "not_configured" { return "未配置" }
            "exit_installer" { return "退出安装程序" }
            "install_cancelled" { return "安装已取消" }
            "detected_installed" { return "检测到已安装的 planify skill" }
            "upgrading" { return "即将升级到最新版本..." }
            "starting_install" { return "开始安装 planify skill..." }
            "downloading" { return "下载" }
            "download_failed" { return "下载失败" }
            "install_success" { return "✅ 安装成功！" }
            "location" { return "位置" }
            "install_failed" { return "❌ 安装失败" }
            "not_configured_warning" { return "⚠️  尚未配置" }
            "create_dir_prompt" { return "是否在当前目录创建" }
            "create_dir_suffix" { return "/skills/ 目录？[y/N]" }
            "usage" { return "使用方法:" }
            "usage_1" { return "  /planify <skill-name>  - 升级指定 skill 为 plan 驱动模式" }
            "usage_2" { return "  /planify               - 交互式选择要升级的 skill" }
            "usage_3" { return "  /planify <prompt>      - 直接跟提示词" }
        }
    } else {
        switch ($Key) {
            "installer_title" { return "Planify Skill Installer" }
            "detecting_config" { return "Detecting AI tool config directories..." }
            "menu_title" { return "Select tool to install/upgrade" }
            "menu_hint_select" { return "Use ↑↓ to select, Enter to confirm" }
            "menu_hint_multi" { return "Use ↑↓ to select, Space to toggle, Enter to confirm" }
            "menu_hint_cancel" { return "Press 0 to cancel" }
            "installed" { return "[installed]" }
            "not_configured" { return "not configured" }
            "exit_installer" { return "Exit installer" }
            "install_cancelled" { return "Installation cancelled" }
            "detected_installed" { return "Existing planify skill detected" }
            "upgrading" { return "Upgrading to latest version..." }
            "starting_install" { return "Starting planify skill installation..." }
            "downloading" { return "Downloading" }
            "download_failed" { return "Download failed" }
            "install_success" { return "✅ Installation successful!" }
            "location" { return "Location" }
            "install_failed" { return "❌ Installation failed" }
            "not_configured_warning" { return "⚠️  Not configured" }
            "create_dir_prompt" { return "Create" }
            "create_dir_suffix" { return "/skills/ directory? [y/N]" }
            "usage" { return "Usage:" }
            "usage_1" { return "  /planify <skill-name>  - Upgrade a skill to plan-driven mode" }
            "usage_2" { return "  /planify               - Interactive skill selection" }
            "usage_3" { return "  /planify <prompt>      - Use with a prompt directly" }
        }
    }
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

    # 根据语言选择 skill 目录
    $skillDir = "planify"
    $skillSubdir = ""
    if (-not (Test-ChineseLanguage)) {
        $skillSubdir = "en/"
    }

    Write-Host ""
    if (Is-Installed -cfgDir $cfgDir) {
        Write-Host "[$toolName] $(Get-Text "detected_installed")" -ForegroundColor Yellow
        Write-Host "$(Get-Text "upgrading")"
    } else {
        Write-Host "[$toolName] $(Get-Text "starting_install")" -ForegroundColor Cyan
    }

    if (-not (Test-Path (Join-Path $cfgDir "skills"))) {
        New-Item -ItemType Directory -Path (Join-Path $cfgDir "skills") | Out-Null
    }
    New-Item -ItemType Directory -Path $target -Force | Out-Null

    $FILES = @("SKILL.md", "example.md", "planify-template.md")

    foreach ($file in $FILES) {
        Write-Host "  $(Get-Text "downloading") $file..."
        $url = "https://raw.githubusercontent.com/$REPO/$BRANCH/.claude/skills/$skillDir/$skillSubdir$file"
        try {
            Invoke-RestMethod -Uri $url -OutFile (Join-Path $target $file) -ErrorAction Stop
        } catch {
            Write-Host "  $(Get-Text "download_failed"): $_" -ForegroundColor Red
            continue
        }
    }

    if (Test-Path (Join-Path $target "SKILL.md"))) {
        Write-Host "  $(Get-Text "install_success")" -ForegroundColor Green
        Write-Host "     $(Get-Text "location"): $target"
    } else {
        Write-Host "  $(Get-Text "install_failed")" -ForegroundColor Red
        $host.UI.RawCursorVisible = $true
        exit 1
    }
}

# 交互式菜单（支持多选）
function Show-InteractiveMenu {
    param(
        [string]$Title,
        [string[]]$Items,
        [switch]$MultiSelect,
        [ref]$SelectedIndices
    )

    $cursor = 0
    $selected = @{}
    $host.UI.RawCursorVisible = $false

    function Draw-Menu {
        Clear-Host

        Write-Host ""
        Write-Host "--- $Title ---" -ForegroundColor Green
        if ($MultiSelect) {
            Write-Host "$(Get-Text "menu_hint_multi")" -ForegroundColor Gray
        } else {
            Write-Host "$(Get-Text "menu_hint_select")" -ForegroundColor Gray
        }
        Write-Host "$(Get-Text "menu_hint_cancel")" -ForegroundColor Gray
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

            # 检查是否是退出选项
            if ($i -eq $ORDERED_INDICES.Count) {
                Write-Host $item
            } elseif ($i -lt $ORDERED_INDICES.Count) {
                $original_idx = $ORDERED_INDICES[$i]
                $dir = $TOOL_DIRS[$original_idx]
                $status = $TOOL_STATUSES[$original_idx]
                $cfg = $ALL_CONFIG_DIRS[$original_idx]
                $tn = Get-ToolName -dir $cfg

                if ($dir -ne "") {
                    Write-Host "$tn  " -NoNewline
                    Write-Host $dir -ForegroundColor Gray -NoNewline
                    if ($status -eq "installed") {
                        Write-Host "  " -NoNewline
                        Write-Host "$(Get-Text "installed")" -ForegroundColor DarkGreen
                    } else {
                        Write-Host ""
                    }
                } else {
                    Write-Host "$tn  ($cfg - $(Get-Text "not_configured"))" -ForegroundColor Gray
                }
            } else {
                Write-Host $item
            }
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

try {
    Clear-Host

    Write-Host ""
    Write-Host "█▀▀█ █░░░ █▀▀█ █▀▀▄ ▀█▀ █▀▀▀ █░░█"
    Write-Host "█▀▀▀ █░░░ █▀▀█ █░░█ ░█░ █▀▀  ▀▀▀█"
    Write-Host "▀░░░ ▀▀▀▀ ▀░░▀ ▀░░▀ ▀▀▀ ▀░░░ ▀▀▀▀"
    Write-Host ""
    Write-Host "$(Get-Text "installer_title")" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "$(Get-Text "detecting_config")"
    Write-Host ""

    $FOUND_DIRS = Find-ProjectConfigs

    # 为每个工具类型找到最近的配置目录
    $TOOL_DIRS = @()  # 按工具顺序存储目录路径（或空字符串）
    $TOOL_STATUSES = @()  # 按工具顺序存储安装状态
    $TOOL_HAS_DIR = @()  # 按工具顺序存储是否有配置目录

    foreach ($cfg in $ALL_CONFIG_DIRS) {
        $foundDir = ""
        # 从 FOUND_DIRS 中查找该工具类型的第一个（最近的）目录
        foreach ($dir in $FOUND_DIRS) {
            $dn = Split-Path $dir -Leaf
            if ($dn -eq $cfg) {
                $foundDir = $dir
                break
            }
        }
        $TOOL_DIRS += $foundDir
        if ($foundDir -ne "" -and (Is-Installed -cfgDir $foundDir)) {
            $TOOL_STATUSES += "installed"
            $TOOL_HAS_DIR += "has_dir"
        } elseif ($foundDir -ne "") {
            $TOOL_STATUSES += "not_installed"
            $TOOL_HAS_DIR += "has_dir"
        } else {
            $TOOL_STATUSES += "not_installed"
            $TOOL_HAS_DIR += "no_dir"
        }
    }

    # 构建菜单项（先已安装，再有目录未安装，最后未配置）
    $MENU_ITEMS = @()
    $ORDERED_INDICES = @()

    # 第一组：已安装的
    for ($i = 0; $i -lt $ALL_CONFIG_DIRS.Count; $i++) {
        if ($TOOL_STATUSES[$i] -eq "installed") {
            $ORDERED_INDICES += $i
        }
    }

    # 第二组：有目录但未安装的
    for ($i = 0; $i -lt $ALL_CONFIG_DIRS.Count; $i++) {
        if ($TOOL_HAS_DIR[$i] -eq "has_dir" -and $TOOL_STATUSES[$i] -ne "installed") {
            $ORDERED_INDICES += $i
        }
    }

    # 第三组：未配置的
    for ($i = 0; $i -lt $ALL_CONFIG_DIRS.Count; $i++) {
        if ($TOOL_HAS_DIR[$i] -eq "no_dir") {
            $ORDERED_INDICES += $i
        }
    }

    # 按顺序构建菜单项（简单字符串数组，实际颜色在 Draw-Menu 中处理）
    $MENU_ITEMS = @()

    foreach ($i in $ORDERED_INDICES) {
        $cfg = $ALL_CONFIG_DIRS[$i]
        $tn = Get-ToolName -dir $cfg
        $dir = $TOOL_DIRS[$i]
        $status = $TOOL_STATUSES[$i]

        if ($dir -ne "") {
            if ($status -eq "installed") {
                $MENU_ITEMS += "$tn  $dir  $(Get-Text "installed")"
            } else {
                $MENU_ITEMS += "$tn  $dir"
            }
        } else {
            $MENU_ITEMS += "$tn  ($cfg - $(Get-Text "not_configured"))"
        }
    }

    # 添加退出选项
    $MENU_ITEMS += "$(Get-Text "exit_installer")"

    # 显示交互式菜单（单选）
    $selectedIndices = @()
    if (Show-InteractiveMenu -Title "$(Get-Text "menu_title")" -Items $MENU_ITEMS -SelectedIndices ([ref]$selectedIndices)) {
        $idx = $selectedIndices[0]

        # 检查是否选择了退出选项
        if ($idx -eq $ORDERED_INDICES.Count) {
            Write-Host "$(Get-Text "install_cancelled")" -ForegroundColor Red
            $host.UI.RawCursorVisible = $true
            exit 0
        }

        $original_idx = $ORDERED_INDICES[$idx]
        $cfg = $ALL_CONFIG_DIRS[$original_idx]
        $dir = $TOOL_DIRS[$original_idx]

        if ($dir -ne "") {
            # 已有配置目录，直接安装
            Do-Install -cfgDir $dir
        } else {
            # 没有配置目录，需要创建
            Write-Host ""
            Write-Host "⚠️  $cfg $(Get-Text "not_configured_warning")" -ForegroundColor Yellow
            Write-Host ""
            $response = Read-Host "$(Get-Text "create_dir_prompt") $cfg$(Get-Text "create_dir_suffix")"
            Write-Host ""

            if ($response -match '^[Yy]$') {
                Do-Install -cfgDir (Join-Path (Get-Location) $cfg)
            } else {
                Write-Host "$(Get-Text "install_cancelled")" -ForegroundColor Red
                $host.UI.RawCursorVisible = $true
                exit 0
            }
        }
    } else {
        Write-Host "$(Get-Text "install_cancelled")" -ForegroundColor Red
        $host.UI.RawCursorVisible = $true
        exit 0
    }

    Write-Host ""
    Write-Host "$(Get-Text "usage")" -ForegroundColor Cyan
    Write-Host "$(Get-Text "usage_1")"
    Write-Host "$(Get-Text "usage_2")"
    Write-Host "$(Get-Text "usage_3")"
    Write-Host ""
} finally {
    # 确保退出时显示光标
    try {
        $host.UI.RawCursorVisible = $true
    } catch {}
}
