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

    while ($currentDir.Parent -ne $null) {
        foreach ($configDir in $CONFIG_DIRS) {
            $testPath = Join-Path $currentDir $configDir
            if (Test-Path $testPath) {
                $foundDirs += $testPath
            }
        }
        $currentDir = $currentDir.Parent
    }

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

# 主逻辑
Write-Host "Planify Skill 安装程序" -ForegroundColor Cyan
Write-Host ""
Write-Host "正在检测 AI 工具配置目录..."
Write-Host ""

$FOUND_DIRS = Find-ExistingConfigDirs

if ($FOUND_DIRS.Count -eq 0) {
    # 未找到任何配置目录
    Write-Host "⚠️  未找到任何 AI 工具配置目录" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "支持的工具：Claude Code, OpenCode, Qwen Qoder, OpenAI Codex, Gemini CLI"
    Write-Host ""
    Write-Host "请选择要创建的配置目录类型："
    Write-Host "  1) Claude Code (.claude/)"
    Write-Host "  2) OpenCode (.opencode/)"
    Write-Host "  3) Qwen Qoder (.qwen/)"
    Write-Host "  4) OpenAI Codex (.codex/)"
    Write-Host "  5) Gemini CLI (.gemini/)"
    Write-Host "  0) 取消安装"
    Write-Host ""

    $selection = Read-Host "请选择 [1-5]"
    Write-Host ""

    $SELECTED_CONFIG = $null
    switch ($selection) {
        "1" { $SELECTED_CONFIG = ".claude" }
        "2" { $SELECTED_CONFIG = ".opencode" }
        "3" { $SELECTED_CONFIG = ".qwen" }
        "4" { $SELECTED_CONFIG = ".codex" }
        "5" { $SELECTED_CONFIG = ".gemini" }
        default {
            Write-Host "无效选择，安装已取消" -ForegroundColor Red
            exit 1
        }
    }

    $response = Read-Host "是否在当前目录创建 $SELECTED_CONFIG/skills/ 目录？[y/N]"
    Write-Host ""
    if ($response -match '^[Yy]$') {
        $SELECTED_DIRS = @(Join-Path (Get-Location) $SELECTED_CONFIG)
    } else {
        Write-Host "安装已取消" -ForegroundColor Red
        exit 1
    }

} elseif ($FOUND_DIRS.Count -eq 1) {
    $SELECTED_DIRS = @($FOUND_DIRS[0])
    Write-Host "找到配置目录：$($FOUND_DIRS[0])" -ForegroundColor Cyan
    Write-Host ""

} else {
    # 找到多个配置目录
    Write-Host "发现多个 AI 工具配置目录：" -ForegroundColor Cyan
    Write-Host ""

    foreach ($d in $FOUND_DIRS) {
        $dn = Split-Path $d -Leaf
        $tn = Get-ToolDisplayName -dir $dn
        Write-Host "  - $tn ($d)" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "将安装到所有检测到的目录"
    Write-Host ""

    $SELECTED_DIRS = $FOUND_DIRS
}

# 安装到每个选中的目录
foreach ($CONFIG_DIR in $SELECTED_DIRS) {
    $CONFIG_NAME = Split-Path $CONFIG_DIR -Leaf
    $TOOL_DISPLAY = Get-ToolDisplayName -dir $CONFIG_NAME
    $TARGET_DIR = Join-Path $CONFIG_DIR "skills"

    if (Test-Path (Join-Path $TARGET_DIR "planify/SKILL.md")) {
        Write-Host ""
        Write-Host "[$TOOL_DISPLAY] 检测到已安装的 planify skill" -ForegroundColor Yellow
        Write-Host "即将升级到最新版本..."
    } else {
        Write-Host ""
        Write-Host "[$TOOL_DISPLAY] 开始安装 planify skill..." -ForegroundColor Cyan
    }

    if (-not (Test-Path $TARGET_DIR)) {
        New-Item -ItemType Directory -Path $TARGET_DIR | Out-Null
    }
    New-Item -ItemType Directory -Path (Join-Path $TARGET_DIR "planify") -Force | Out-Null

    $FILES = @("SKILL.md", "example.md", "planify-template.md")

    foreach ($file in $FILES) {
        Write-Host "  下载 $file..."
        $url = "https://raw.githubusercontent.com/$REPO/$BRANCH/$CONFIG_NAME/skills/planify/$file"
        try {
            Invoke-RestMethod -Uri $url -OutFile (Join-Path $TARGET_DIR "planify/$file") -ErrorAction Stop
        } catch {
            Write-Host "  下载失败：$_" -ForegroundColor Red
            continue
        }
    }

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
