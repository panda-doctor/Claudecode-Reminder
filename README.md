# ClaudeCode Reminder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue.svg)](https://www.microsoft.com/windows)

为 **Claude Code CLI** 提供 Windows 桌面通知提醒。**智能检测前台窗口**——只在离开 CLI 界面时弹出，正在使用时不会打扰你。

## 核心特性

- **前台感知** — 检测到 Claude Code / 终端为当前窗口时自动跳过通知
- **零依赖回退** — plyer 不可用时自动切换为 Windows 原生 Toast 通知
- **按类型区分** — 权限确认、等待输入、任务完成三种场景不同标题和超时
- **一键安装** — 自动创建虚拟环境、安装依赖、配置 hooks、备份原设置

## 通知场景

| 场景 | Hook 类型 | 标题 | 超时 |
|------|-----------|------|------|
| 完成任务 | `Stop` | Claude Code — 任务完成 | 10s |
| 需要授权 | `PermissionRequest` | Claude Code — 权限确认 | 12s |
| 等待输入 | `Notification` | Claude Code — 等待输入 | 10s |

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
4. 部署 `send_notification.py` 通知发送脚本（包含前台检测 + PowerShell 回退）
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
  "你好，这是一条测试消息" --type default
```

> 注意：如果当前窗口是 Claude Code 或终端，通知会被自动跳过。可以先切到其他窗口再测试。

## 自定义配置

### 修改通知文字

编辑 `~/.claude/settings.json`，找到对应 hook 的 `command` 字段，修改 `--type <type>` 后的消息文本。

### 修改通知停留时间

编辑 `~/.claude/scripts/send_notification.py`，修改 `TYPE_CONFIG` 字典中对应类型的 `timeout` 值（单位：秒）。

```python
TYPE_CONFIG = {
    "permission": {
        "title": "Claude Code — 权限确认",
        "timeout": 12,   # 权限确认显示 12 秒
    },
    "notification": {
        "title": "Claude Code — 等待输入",
        "timeout": 10,   # 等待输入显示 10 秒
    },
    ...
}
```

### 禁用某个通知

在 `~/.claude/settings.json` 中删除对应的 hook 块即可。例如只想保留任务完成提醒，删除 `PermissionRequest` 和 `Notification` 配置。

### 自定义终端匹配关键词

如果你的终端未被识别，编辑 `send_notification.py` 中的 `terminal_keywords` 列表，添加你的终端名称（如 "cursor"、"vscode" 等）。

## 工作原理

```
触发 hook
   ↓
send_notification.py --type <type> <message>
   ↓
检测前台窗口标题（ctypes 调用 Win32 API）
   ↓
是 Claude Code / 终端窗口？
   ├── 是 → 静默退出（不打扰用户）
   └── 否 → plyer 发送通知
              ├── 成功 → 完成
              └── 失败 → PowerShell Toast 回退
```

## 故障排查

### 看不到通知弹窗

1. 确认当前窗口不是 Claude Code / 终端（前台检测会跳过通知）
2. 打开 **Windows 设置** → **系统** → **通知**
3. 确保 "获取来自应用和其他发送者的通知" 已开启
4. 在列表中找到 **Python**，确保通知开关已打开

### 通知被静默

1. 检查系统右下角通知中心的 **免打扰模式（聚焦助手）** 是否开启
2. 如已开启，将 Python 添加到优先列表

### plyer 安装失败

```powershell
& "$env:USERPROFILE\.claude\scripts\.venv\Scripts\pip.exe" install plyer --force-reinstall
```

### 还原设置

安装脚本会自动备份 `settings.json`，备份文件位于同目录下，格式为 `settings.json.backup.20240620_160000`。

## 命令行用法

```powershell
python send_notification.py [消息...] --type [permission|notification|stop|default]

# 示例
python send_notification.py 需要授权 --type permission
python send_notification.py 任务完成 --type stop
python send_notification.py 自定义消息 --type default
```

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
