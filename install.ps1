# install.ps1
# 一键安装 planify skill 到当前工程目录 (Windows PowerShell)
# 使用方法：iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex

$ErrorActionPreference = "Stop"

# 仓库信息
$REPO = "jayli/plan-kit"
$BRANCH = if ($env:PLAN_KIT_BRANCH) { $env:PLAN_KIT_BRANCH } else { "main" }

# 向上查找 .claude 目录
function Find-ClaudeDir {
    $currentDir = Get-Location
    $claudeDir = $null

    # 从当前目录向上查找
    while ($currentDir.Parent -ne $null) {
        $testPath = Join-Path $currentDir ".claude"
        if (Test-Path $testPath) {
            $claudeDir = $testPath
            break
        }
        $currentDir = $currentDir.Parent
    }

    # 如果没找到，检查家目录
    if ($null -eq $claudeDir) {
        $homeClaude = Join-Path $HOME ".claude"
        if (Test-Path $homeClaude) {
            $claudeDir = $homeClaude
        }
    }

    return $claudeDir
}

# 查找 .claude 目录
$CLAUDE_DIR = Find-ClaudeDir

if ($null -ne $CLAUDE_DIR -and (Test-Path $CLAUDE_DIR)) {
    Write-Host "找到 .claude 目录：$CLAUDE_DIR" -ForegroundColor Cyan
    Write-Host ""
    $TARGET_DIR = Join-Path $CLAUDE_DIR "skills"
} else {
    Write-Host "⚠️  未找到 .claude 目录" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "当前项目尚未被 Claude 初始化。"
    Write-Host ""

    $response = Read-Host "是否在当前目录创建 .claude/skills/ 目录？[y/N]"
    if ($response -match '^[Yy]$') {
        $TARGET_DIR = Join-Path (Get-Location) ".claude/skills"
        Write-Host "将在当前目录创建 .claude/skills/..." -ForegroundColor Cyan
    } else {
        Write-Host "安装已取消" -ForegroundColor Red
        exit 1
    }
}

# 检查是否已安装
if (Test-Path (Join-Path $TARGET_DIR "planify/SKILL.md")) {
    Write-Host "检测到已安装的 planify skill" -ForegroundColor Yellow
    Write-Host "即将升级到最新版本..." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "🚀 开始安装 planify skill..."

# 创建目标目录（如果不存在）
if (-not (Test-Path $TARGET_DIR)) {
    New-Item -ItemType Directory -Path $TARGET_DIR | Out-Null
}
New-Item -ItemType Directory -Path (Join-Path $TARGET_DIR "planify") -Force | Out-Null

# 定义要下载的文件
$FILES = @("SKILL.md", "example.md", "planify-template.md")

# 从 GitHub 下载每个文件
foreach ($file in $FILES) {
    $url = "https://raw.githubusercontent.com/$REPO/$BRANCH/.claude/skills/planify/$file"
    Write-Host "下载 $file..."
    $destPath = Join-Path $TARGET_DIR "planify/$file"
    Invoke-RestMethod -Uri $url -OutFile $destPath
}

# 验证安装
if (Test-Path (Join-Path $TARGET_DIR "planify/SKILL.md")) {
    Write-Host ""
    Write-Host "✅ planify skill 安装成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "安装位置：$TARGET_DIR\planify"
    Write-Host ""
    Write-Host "使用方法:"
    Write-Host "  /planify <skill-name>  - 升级指定 skill 为 plan 驱动模式"
    Write-Host "  /planify               - 交互式选择要升级的 skill"
} else {
    Write-Host "❌ 安装失败" -ForegroundColor Red
    exit 1
}
