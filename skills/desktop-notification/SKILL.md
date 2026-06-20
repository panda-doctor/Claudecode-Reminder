---
name: desktop-notification
description: >
  Windows桌面提醒配置。为Claude Code设置任务完成、权限请求、空闲等待等场景的桌面通知。
  智能检测前台窗口——只在离开 CLI 界面时弹窗，正在使用时不会打扰。
  Triggers: 桌面通知, 桌面提醒, 通知配置, desktop notification, 系统通知, toast notification.
license: MIT
metadata:
  version: "2.0"
  category: system
---

# 桌面通知 - Claude Code Desktop Notification

让 Claude Code CLI 在需要你关注时发送 Windows 桌面通知。**智能前台感知**——检测到你正在看 CLI 时自动静默，切走才弹窗。

## 支持的场景

| Hook | 触发时机 | 标题 | 超时 |
|------|----------|------|------|
| **Stop** | 任务处理完成 | Claude Code — 任务完成 | 10s |
| **PermissionRequest** | 需要用户授权 | Claude Code — 权限确认 | 12s |
| **Notification** | 等待输入/空闲 | Claude Code — 等待输入 | 10s |

## 核心特性

- **前台感知** — `ctypes` 调用 Win32 API 检测前台窗口，Claude Code / 终端窗口自动跳过通知
- **零依赖回退** — `plyer` 不可用时自动切换为 Windows 原生 Toast 通知（PowerShell）
- **类型系统** — `--type permission|notification|stop|default` 预设标题和超时参数

## 快速安装

在 PowerShell 中运行：

```powershell
git clone https://github.com/panda-doctor/Claudecode-Reminder.git $env:TEMP\Claudecode-Reminder
& "$env:TEMP\Claudecode-Reminder\install.ps1"
```

## 手动安装

### 1. 环境准备

```powershell
python -m venv "$env:USERPROFILE\.claude\scripts\.venv"
& "$env:USERPROFILE\.claude\scripts\.venv\Scripts\pip.exe" install plyer
```

### 2. 部署脚本

将 `send_notification.py` 复制到 `~/.claude/scripts/` 目录。

### 3. 配置 Hooks

在 `~/.claude/settings.json` 中配置 Stop、PermissionRequest、Notification 三个 hooks，使用 `--type` 参数：

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "pythonw.exe send_notification.py --type stop 本次任务处理完毕，可以回来查看结果了"
      }]
    }],
    "PermissionRequest": [{
      "matcher": "Task|TaskOutput|Bash|Glob|Grep|ExitPlanMode|Read|Edit|Write|NotebookEdit|WebFetch|WebSearch|AskUserQuestion|Skill|EnterPlanMode",
      "hooks": [{
        "type": "command",
        "command": "pythonw.exe send_notification.py --type permission 需要你的授权以继续执行操作 — 请回到 Claude Code 窗口确认"
      }]
    }],
    "Notification": [{
      "matcher": "permission_prompt|idle_prompt|auth_success|elicitation_dialog",
      "hooks": [{
        "type": "command",
        "command": "pythonw.exe send_notification.py --type notification 处理已暂停，需要你继续输入或做出选择"
      }]
    }]
  }
}
```

详细配置参见仓库 README.md 和 install.ps1。

## 测试通知

```powershell
& "$env:USERPROFILE\.claude\scripts\.venv\Scripts\python.exe" `
  "$env:USERPROFILE\.claude\scripts\send_notification.py" `
  "这是一条测试消息" --type default
```

> 注意：如果当前窗口是 Claude Code 或终端，通知会被前台检测跳过。

## 自定义通知外观

编辑 `~/.claude/scripts/send_notification.py` 中的 `TYPE_CONFIG` 字典：

```python
TYPE_CONFIG = {
    "permission": {"title": "...", "timeout": 12},
    "notification": {"title": "...", "timeout": 10},
    "stop": {"title": "...", "timeout": 10},
    "default": {"title": "Claude Code", "timeout": 10},
}
```

## 终端关键词配置

如果前台检测未识别你的终端，编辑 `is_claude_active()` 中的 `terminal_keywords`：

```python
terminal_keywords = [
    "powershell", "cmd.exe", "windows terminal",
    "terminal", "tabby", "wezterm", "alacritty",
    # 添加你的终端名称
]
```

## 故障排查

| 问题 | 解决方案 |
|------|----------|
| 看不到通知 | 确认当前不在 CLI 界面；Windows 设置 -> 系统 -> 通知 -> 打开 Python 通知 |
| 免打扰模式阻止 | 关闭免打扰或添加 Python 到优先列表 |
| plyer 报错 | 进入 venv 运行 `pip install plyer`；脚本会自动回退到 PowerShell Toast |
| 通知一闪而过 | 增大 `TYPE_CONFIG` 中对应类型的 `timeout` 参数 |
| 前台检测不生效 | 检查终端窗口标题是否包含 `terminal_keywords` 中的关键词 |

## 仓库地址

https://github.com/panda-doctor/Claudecode-Reminder
