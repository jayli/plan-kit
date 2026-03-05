# install.ps1
# 一键安装 planify skill 到当前工程目录 (Windows PowerShell)
# 使用方法：iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex

$ErrorActionPreference = "Stop"

# 仓库信息
$REPO = "jayli/plan-kit"
$BRANCH = if ($env:PLAN_KIT_BRANCH) { $env:PLAN_KIT_BRANCH } else { "main" }

# 支持的配置目录列表
$CONFIG_DIRS = @(".claude", ".opencode", ".qwen", ".codex", ".gemini")

# 获取工具显示名称
function Get-ToolDisplayName {
    param([string]$dir)
    $toolMap = @{
        ".claude" = "Claude Code"
        ".opencode" = "OpenCode"
        ".qwen" = "Qwen Qoder"
        ".codex" = "OpenAI Codex"
        ".gemini" = "Gemini CLI"
    }
    return $toolMap[$dir] ?? $dir
}

# 向上查找所有存在的配置目录
function Find-ExistingConfigDirs {
    $currentDir = Get-Location
    $foundDirs = @()

    # 从当前目录向上查找
    while ($currentDir.Parent -ne $null) {
        foreach ($configDir in $CONFIG_DIRS) {
            $testPath = Join-Path $currentDir $configDir
            if (Test-Path $testPath) {
                $foundDirs += $testPath
            }
        }
        $currentDir = $currentDir.Parent
    }

    # 如果没找到，检查家目录
    if ($foundDirs.Count -eq 0) {
        foreach ($configDir in $CONFIG_DIRS) {
            $homeConfig = Join-Path $HOME $configDir
            if (Test-Path $homeConfig) {
                $foundDirs += $homeConfig
            }
        }
    }

    return $foundDirs
}

# 交互式菜单（使用 PowerShell 原生支持）
function Show-InteractiveMenu {
    param(
        [string[]]$Items,
        [string]$Title = "请选择",
        [switch]$MultiSelect
    )

    $cursor = 0
    $selected = @{}

    # 隐藏光标
    $host.UI.RawCursorVisible = $false

    # 清屏并保存位置
    $savedCursor = $host.UI.RawUI.CursorPosition
    $windowSize = $host.UI.RawUI.WindowSize

    function Draw-Menu {
        Clear-Host
        Write-Host $Title -ForegroundColor Cyan
        Write-Host ""
        if ($MultiSelect) {
            Write-Host "使用 ↑↓ 选择，空格 选中/取消，Enter 确认" -ForegroundColor Gray
        } else {
            Write-Host "使用 ↑↓ 选择，Enter 确认" -ForegroundColor Gray
        }
        Write-Host ""

        for ($i = 0; $i -lt $Items.Count; $i++) {
            $item = $Items[$i]
            $name = Split-Path $item -Leaf
            $toolName = Get-ToolDisplayName -dir $name

            if ($i -eq $cursor) {
                if ($MultiSelect -and $selected.ContainsKey($i)) {
                    Write-Host "  ▶ [✓] $toolName ($item)" -ForegroundColor Cyan
                } else {
                    Write-Host "  ▶ [ ] $toolName ($item)" -ForegroundColor Cyan
                }
            } else {
                if ($MultiSelect -and $selected.ContainsKey($i)) {
                    Write-Host "    [✓] $toolName ($item)" -ForegroundColor Green
                } else {
                    Write-Host "    [ ] $toolName ($item)"
                }
            }
        }
        Write-Host ""
        Write-Host "  [0] 取消安装" -ForegroundColor Gray
    }

    Draw-Menu

    while ($true) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                if ($cursor -gt 0) {
                    $cursor--
                    Draw-Menu
                }
            }
            40 { # Down arrow
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
                        # 没有选择时默认选中当前项
                        return @($Items[$cursor])
                    }
                    return @($selected.Keys | Sort-Object | ForEach-Object { $Items[$_] })
                } else {
                    return @($Items[$cursor])
                }
            }
            48 { # 0
                $host.UI.RawCursorVisible = $true
                return @()
            }
        }
    }
}

# 主逻辑
Write-Host "Planify Skill 安装程序" -ForegroundColor Cyan
Write-Host ""
Write-Host "正在检测 AI 工具配置目录..."
Write-Host ""

$FOUND_DIRS = Find-ExistingConfigDirs

$SELECTED_DIRS = @()

if ($FOUND_DIRS.Count -gt 1) {
    # 发现多个配置目录，使用交互式菜单
    Write-Host "发现多个 AI 工具配置目录：" -ForegroundColor Cyan
    Write-Host ""

    $result = Show-InteractiveMenu -Items $FOUND_DIRS -Title "选择要安装的目标目录" -MultiSelect

    if ($result.Count -eq 0) {
        Write-Host "安装已取消" -ForegroundColor Red
        exit 1
    fi

    $SELECTED_DIRS = $result

} elseif ($FOUND_DIRS.Count -eq 1) {
    $SELECTED_DIRS = @($FOUND_DIRS[0])
    Write-Host "找到配置目录：$($FOUND_DIRS[0])" -ForegroundColor Cyan
    Write-Host ""
} else {
    # 未找到任何配置目录
    Write-Host "⚠️  未找到任何 AI 工具配置目录" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "支持的工具：Claude Code, OpenCode, Qwen Qoder, OpenAI Codex, Gemini CLI"
    Write-Host ""

    $options = @(
        @{Path = ".claude"; Name = "Claude Code"},
        @{Path = ".opencode"; Name = "OpenCode"},
        @{Path = ".qwen"; Name = "Qwen Qoder"},
        @{Path = ".codex"; Name = "OpenAI Codex"},
        @{Path = ".gemini"; Name = "Gemini CLI"}
    )

    $optionPaths = $options | ForEach-Object { Join-Path (Get-Location) $_.Path }
    $optionNames = $options | ForEach-Object { "$($_.Name) ($($_.Path))" }

    $result = Show-InteractiveMenu -Items $optionNames -Title "选择要创建的配置目录类型" -MultiSelect:$false

    if ($result.Count -eq 0) {
        Write-Host "安装已取消" -ForegroundColor Red
        exit 1
    }

    $selectedIndex = [array]::IndexOf($optionNames, $result[0])
    $SELECTED_CONFIG = $options[$selectedIndex].Path

    $response = Read-Host "是否在当前目录创建 $SELECTED_CONFIG/skills/ 目录？[y/N]"
    Write-Host ""
    if ($response -match '^[Yy]$') {
        $SELECTED_DIRS = @(Join-Path (Get-Location) $SELECTED_CONFIG)
    } else {
        Write-Host "安装已取消" -ForegroundColor Red
        exit 1
    }
}

# 安装到每个选中的目录
foreach ($CONFIG_DIR in $SELECTED_DIRS) {
    $CONFIG_NAME = Split-Path $CONFIG_DIR -Leaf
    $TOOL_DISPLAY = Get-ToolDisplayName -dir $CONFIG_NAME
    $TARGET_DIR = Join-Path $CONFIG_DIR "skills"

    # 检查是否已安装
    if (Test-Path (Join-Path $TARGET_DIR "planify/SKILL.md")) {
        Write-Host ""
        Write-Host "[$TOOL_DISPLAY] 检测到已安装的 planify skill" -ForegroundColor Yellow
        Write-Host "即将升级到最新版本..."
    } else {
        Write-Host ""
        Write-Host "[$TOOL_DISPLAY] 开始安装 planify skill..." -ForegroundColor Cyan
    }

    # 创建目标目录
    if (-not (Test-Path $TARGET_DIR)) {
        New-Item -ItemType Directory -Path $TARGET_DIR | Out-Null
    }
    New-Item -ItemType Directory -Path (Join-Path $TARGET_DIR "planify") -Force | Out-Null

    # 下载文件
    $FILES = @("SKILL.md", "example.md", "planify-template.md")

    foreach ($file in $FILES) {
        Write-Host "  下载 $file..."
        $url = "https://raw.githubusercontent.com/$REPO/$BRANCH/$CONFIG_NAME/skills/planify/$file"
        $destPath = Join-Path $TARGET_DIR "planify/$file"
        try {
            Invoke-RestMethod -Uri $url -OutFile $destPath -ErrorAction Stop
        } catch {
            Write-Host "  下载失败：$_" -ForegroundColor Red
            continue
        }
    }

    # 验证安装
    if (Test-Path (Join-Path $TARGET_DIR "planify/SKILL.md")) {
        Write-Host "  ✅ planify skill 安装成功！" -ForegroundColor Green
        Write-Host "     安装位置：$TARGET_DIR\planify"
    } else {
        Write-Host "  ❌ 安装失败" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "使用方法:" -ForegroundColor Cyan
Write-Host "  /planify <skill-name>  - 升级指定 skill 为 plan 驱动模式"
Write-Host "  /planify               - 交互式选择要升级的 skill"
