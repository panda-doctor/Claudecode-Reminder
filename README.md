# ClaudeCode Reminder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue.svg)](https://www.microsoft.com/windows)

为 **Claude Code CLI** 提供 Windows 桌面通知提醒，让你在离开电脑时也能及时知道 Claude Code 需要你的关注。

## 效果演示

当 Claude Code 需要你授权、等待输入、或任务完成时，Windows 桌面会弹出通知：

```
┌──────────────────────────────────────┐
│  Claude Code                         │
│                                      │
│  需要授权：请回到 Claude Code          │
│  确认操作                             │
│                                      │
└──────────────────────────────────────┘
```

## 通知场景

| 场景 | Hook 类型 | 触发条件 |
|------|-----------|----------|
| 完成任务 | `Stop` | Claude Code 处理完请求 |
| 需要授权 | `PermissionRequest` | 执行需确认的操作（Bash/Edit/Write 等） |
| 等待输入 | `Notification` | 空闲提示 / 权限弹窗 / 用户选择对话框 |

## 一键安装

### 方式一：在线安装

```powershell
git clone https://github.com/panda-doctor/Claudecode-Reminder.git $env:TEMP\Claudecode-Reminder
& "$env:TEMP\Claudecode-Reminder\install.ps1"
```

### 方式二：本地安装

下载仓库后，在仓库目录下运行：

```powershell
.\install.ps1
```

### 方式三：作为 Claude Code Skill 安装

将仓库中的 `skills/desktop-notification/` 整个文件夹复制到 `~/.claude/skills/` 目录下：

```powershell
Copy-Item -Recurse ".\skills\desktop-notification" "$env:USERPROFILE\.claude\skills\desktop-notification"
```

重启 Claude Code 后，输入 `/desktop-notification` 即可使用技能进行管理。

## 安装脚本做了什么

安装脚本会按顺序执行以下操作：

1. 检查 Python 3.7+ 环境
2. 在 `~/.claude/scripts/.venv` 创建 Python 虚拟环境
3. 安装 `plyer` 桌面通知库
4. 部署 `send_notification.py` 通知发送脚本
5. 安装 Claude Code Skill 定义文件
6. 在 `~/.claude/settings.json` 中配置 3 个 hooks（**自动备份原文件**）
7. 发送一条测试通知验证安装成功

## 前置要求

- **Windows 10 / 11**
- **Python 3.7+** ([下载](https://www.python.org/downloads/))
- **Claude Code CLI** ([安装](https://docs.anthropic.com/en/docs/claude-code))

## 测试

手动发送一条测试通知：

```powershell
& "$env:USERPROFILE\.claude\scripts\.venv\Scripts\python.exe" `
  "$env:USERPROFILE\.claude\scripts\send_notification.py" `
  "你好，这是一条测试消息" --title "Claude Code"
```

## 自定义配置

### 修改通知文字

编辑 `~/.claude/settings.json`，找到对应 hook 的 `command` 字段，修改末尾的消息文本。

### 修改通知停留时间

编辑 `~/.claude/scripts/send_notification.py`，修改第 9 行的 `timeout` 参数（单位：秒）。

```python
notification.notify(
    title=title,
    message=message,
    timeout=10,  # 改为 10 秒
)
```

### 禁用某个通知

在 `~/.claude/settings.json` 中删除对应的 hook 块即可。例如只想保留任务完成提醒，删除 `PermissionRequest` 和 `Notification` 配置。

## 故障排查

### 看不到通知弹窗

1. 打开 **Windows 设置** → **系统** → **通知**
2. 确保 "获取来自应用和其他发送者的通知" 已开启
3. 在列表中找到 **Python**，确保通知开关已打开

### 通知被静默

1. 检查系统右下角通知中心的 **免打扰模式（聚焦助手）** 是否开启
2. 如已开启，将 Python 添加到优先列表

### plyer 安装失败

```powershell
& "$env:USERPROFILE\.claude\scripts\.venv\Scripts\pip.exe" install plyer --force-reinstall
```

### 还原设置

安装脚本会自动备份 `settings.json`，备份文件位于同目录下，格式为 `settings.json.backup.20240620_160000`。

## 文件结构

```
Claudecode-Reminder/
├── README.md                          # 本文件
├── LICENSE                            # MIT 许可证
├── install.ps1                        # Windows PowerShell 一键安装脚本
├── send_notification.py               # 桌面通知发送核心脚本
└── skills/
    └── desktop-notification/
        └── SKILL.md                   # Claude Code Skill 定义
```

## License

MIT © 2024
