<#
.SYNOPSIS
    Claude Code 桌面通知一键安装脚本
.DESCRIPTION
    为 Claude Code CLI 安装 Windows 桌面通知功能。
    仓库地址: https://github.com/panda-doctor/Claudecode-Reminder
    支持:
    1. 创建 Python 虚拟环境
    2. 安装 plyer 依赖
    3. 部署通知发送脚本
    4. 安装 Claude Code Skill
    5. 配置 settings.json hooks
.NOTES
    需要 Python 3.7+ 已安装并在 PATH 中
    以管理员身份运行 PowerShell 可获得最佳体验
#>

$ErrorActionPreference = "Stop"
$CLAUDE_DIR = "$env:USERPROFILE\.claude"
$SCRIPTS_DIR = "$CLAUDE_DIR\scripts"
$VENV_DIR = "$SCRIPTS_DIR\.venv"
$SKILL_DIR = "$CLAUDE_DIR\skills\desktop-notification"
$NOTIFY_SCRIPT = "$SCRIPTS_DIR\send_notification.py"
$SETTINGS_FILE = "$CLAUDE_DIR\settings.json"
$PYTHON_EXE = "$VENV_DIR\Scripts\python.exe"

# 获取脚本所在目录（仓库根目录）
$REPO_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Claude Code 桌面通知 - 一键安装脚本" -ForegroundColor Cyan
Write-Host "  github.com/panda-doctor/Claudecode-Reminder" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: 检查 Python
Write-Host "[1/6] 检查 Python 环境..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  OK $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  FAIL 未找到 Python，请先安装 Python 3.7+" -ForegroundColor Red
    Write-Host "    下载地址: https://www.python.org/downloads/" -ForegroundColor Red
    exit 1
}

# Step 2: 创建虚拟环境
Write-Host "[2/6] 创建 Python 虚拟环境..." -ForegroundColor Yellow
if (Test-Path $VENV_DIR) {
    Write-Host "  SKIP 虚拟环境已存在" -ForegroundColor Gray
} else {
    New-Item -ItemType Directory -Path $SCRIPTS_DIR -Force | Out-Null
    python -m venv $VENV_DIR
    Write-Host "  OK 虚拟环境创建完成" -ForegroundColor Green
}

# Step 3: 安装 plyer
Write-Host "[3/6] 安装 plyer 依赖..." -ForegroundColor Yellow
& "$VENV_DIR\Scripts\pip.exe" install plyer --quiet 2>&1 | Out-Null
Write-Host "  OK plyer 安装完成" -ForegroundColor Green

# Step 4: 部署通知脚本
Write-Host "[4/6] 部署通知发送脚本..." -ForegroundColor Yellow
$repoScript = Join-Path $REPO_DIR "send_notification.py"
if (Test-Path $repoScript) {
    Copy-Item $repoScript $NOTIFY_SCRIPT -Force
    Write-Host "  OK 从仓库复制脚本到: $NOTIFY_SCRIPT" -ForegroundColor Green
} else {
    # 内嵌生成
    $scriptContent = @'
import sys
import argparse
from plyer import notification


def send_notify(title: str, message: str) -> None:
    notification.notify(
        title=title,
        message=message,
        timeout=5,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Send desktop notification.")
    parser.add_argument("message", nargs="+", help="Notification message")
    parser.add_argument("--title", default="Claude Code", help="Notification title")
    args = parser.parse_args()

    message = " ".join(args.message)
    send_notify(args.title, message)


if __name__ == "__main__":
    main()
'@
    Set-Content -Path $NOTIFY_SCRIPT -Value $scriptContent -Encoding UTF8
    Write-Host "  OK 脚本已创建: $NOTIFY_SCRIPT" -ForegroundColor Green
}

# Step 5: 安装 Claude Code Skill
Write-Host "[5/6] 安装 Claude Code Skill..." -ForegroundColor Yellow
$repoSkill = Join-Path $REPO_DIR "skills\desktop-notification\SKILL.md"
if (Test-Path $repoSkill) {
    New-Item -ItemType Directory -Path $SKILL_DIR -Force | Out-Null
    Copy-Item $repoSkill (Join-Path $SKILL_DIR "SKILL.md") -Force
    Write-Host "  OK Skill 已安装到: $SKILL_DIR" -ForegroundColor Green
} else {
    Write-Host "  SKIP 未找到 Skill 文件" -ForegroundColor Gray
}

# Step 6: 配置 hooks
Write-Host "[6/6] 配置 settings.json hooks..." -ForegroundColor Yellow

$HOOK_CMD_STOP = "$PYTHON_EXE $NOTIFY_SCRIPT Claude Code 已完成本次任务"
$HOOK_CMD_PERMISSION = "$PYTHON_EXE $NOTIFY_SCRIPT 需要授权：请回到 Claude Code 确认操作"
$HOOK_CMD_NOTIFICATION = "$PYTHON_EXE $NOTIFY_SCRIPT Claude Code 等待你的输入或选择"
$PERMISSION_MATCHER = "Task|TaskOutput|Bash|Glob|Grep|ExitPlanMode|Read|Edit|Write|NotebookEdit|WebFetch|WebSearch|AskUserQuestion|Skill|EnterPlanMode"
$NOTIFICATION_MATCHER = "permission_prompt|idle_prompt|auth_success|elicitation_dialog"

if (Test-Path $SETTINGS_FILE) {
    $settings = Get-Content $SETTINGS_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
    # 备份原设置
    $backupFile = "$SETTINGS_FILE.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $SETTINGS_FILE $backupFile
    Write-Host "  -- 原设置已备份到: $backupFile" -ForegroundColor Gray
} else {
    $settings = @{}
}

if (-not $settings.hooks) {
    $settings | Add-Member -MemberType NoteProperty -Name "hooks" -Value @{}
}

# Stop hook
$settings.hooks | Add-Member -MemberType NoteProperty -Name "Stop" -Value @(
    @{
        matcher = ""
        hooks = @(
            @{ type = "command"; command = $HOOK_CMD_STOP }
        )
    }
) -Force

# PermissionRequest hook
$settings.hooks | Add-Member -MemberType NoteProperty -Name "PermissionRequest" -Value @(
    @{
        matcher = $PERMISSION_MATCHER
        hooks = @(
            @{ type = "command"; command = $HOOK_CMD_PERMISSION }
        )
    }
) -Force

# Notification hook
$settings.hooks | Add-Member -MemberType NoteProperty -Name "Notification" -Value @(
    @{
        matcher = $NOTIFICATION_MATCHER
        hooks = @(
            @{ type = "command"; command = $HOOK_CMD_NOTIFICATION }
        )
    }
) -Force

$settings | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE -Encoding UTF8
Write-Host "  OK settings.json 已更新" -ForegroundColor Green

# 测试通知
Write-Host ""
Write-Host "测试通知..." -ForegroundColor Yellow
& $PYTHON_EXE $NOTIFY_SCRIPT "安装成功！Claude Code 桌面通知已就绪" --title "Claude Code"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  安装完成！" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "已配置以下通知场景:" -ForegroundColor White
Write-Host "  * Stop             - 任务完成时提醒" -ForegroundColor Gray
Write-Host "  * PermissionRequest - 需要授权时提醒" -ForegroundColor Gray
Write-Host "  * Notification     - 等待输入时提醒" -ForegroundColor Gray
Write-Host ""
Write-Host "输入 /desktop-notification 管理通知设置" -ForegroundColor White
Write-Host ""
Write-Host "如果没看到通知弹窗，请检查:" -ForegroundColor Yellow
Write-Host "  设置 -> 系统 -> 通知 -> Python 通知是否开启" -ForegroundColor Gray
