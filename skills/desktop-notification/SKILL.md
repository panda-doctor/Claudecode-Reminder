---
name: desktop-notification
description: >
  Windows桌面提醒配置。为Claude Code设置任务完成、权限请求、空闲等待等场景的桌面通知。
  Triggers: 桌面通知, 桌面提醒, 通知配置, desktop notification, 系统通知, toast notification.
license: MIT
metadata:
  version: "1.0"
  category: system
---

# 桌面通知 - Claude Code Desktop Notification

让 Claude Code CLI 在需要你关注时发送 Windows 桌面通知。

## 支持的场景

| Hook | 触发时机 | 默认消息 |
|------|----------|----------|
| **Stop** | 任务处理完成 | "Claude Code 已完成本次任务" |
| **PermissionRequest** | 需要用户授权 | "需要授权：请回到 Claude Code 确认操作" |
| **Notification** | 等待输入/空闲 | "Claude Code 等待你的输入或选择" |

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

在 `~/.claude/settings.json` 中配置 Stop、PermissionRequest、Notification 三个 hooks。

详细配置参见仓库 README.md 和 install.ps1。

## 测试通知

```powershell
& "$env:USERPROFILE\.claude\scripts\.venv\Scripts\python.exe" `
  "$env:USERPROFILE\.claude\scripts\send_notification.py" `
  "这是一条测试消息" --title "Claude Code 测试"
```

## 故障排查

| 问题 | 解决方案 |
|------|----------|
| 看不到通知 | Windows 设置 -> 系统 -> 通知 -> 打开 Python 通知 |
| 免打扰模式阻止 | 关闭免打扰或添加 Python 到优先列表 |
| plyer 报错 | 进入 venv 运行 `pip install plyer` |
| 通知一闪而过 | 增大 `send_notification.py` 中的 `timeout` 参数 |

## 仓库地址

https://github.com/panda-doctor/Claudecode-Reminder
