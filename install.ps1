# install.ps1
# 一键安装 planify skill 到当前工程目录 (Windows PowerShell)
# 使用方法：iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex

$ErrorActionPreference = "Stop"

# 仓库信息
$REPO = "jayli/plan-kit"
$BRANCH = $env:PLAN_KIT_BRANCH ?? "main"

# 目标目录：当前工程的 .claude/skills
$TARGET_DIR = Join-Path (Get-Location) ".claude/skills/planify"

Write-Host "🚀 开始安装 planify skill..."

# 创建目标目录（如果不存在）
if (-not (Test-Path $TARGET_DIR)) {
    New-Item -ItemType Directory -Path $TARGET_DIR | Out-Null
}

# 定义要下载的文件
$FILES = @("SKILL.md", "example.md", "planify-template.md")

# 从 GitHub 下载每个文件
foreach ($file in $FILES) {
    $url = "https://raw.githubusercontent.com/$REPO/$BRANCH/.claude/skills/planify/$file"
    Write-Host "下载 $file..."
    Invoke-RestMethod -Uri $url -OutFile (Join-Path $TARGET_DIR $file)
}

# 验证安装
if (Test-Path (Join-Path $TARGET_DIR "SKILL.md")) {
    Write-Host ""
    Write-Host "✅ planify skill 安装成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "安装位置：$TARGET_DIR"
    Write-Host ""
    Write-Host "使用方法:"
    Write-Host "  /planify <skill-name>  - 升级指定 skill 为 plan 驱动模式"
    Write-Host "  /planify               - 交互式选择要升级的 skill"
} else {
    Write-Host "❌ 安装失败" -ForegroundColor Red
    exit 1
}
