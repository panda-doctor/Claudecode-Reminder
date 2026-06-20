import sys
import ctypes
import subprocess
import argparse


TYPE_CONFIG = {
    "permission": {
        "title": "Claude Code — 权限确认",
        "timeout": 12,
    },
    "notification": {
        "title": "Claude Code — 等待输入",
        "timeout": 10,
    },
    "stop": {
        "title": "Claude Code — 任务完成",
        "timeout": 10,
    },
    "default": {
        "title": "Claude Code",
        "timeout": 10,
    },
}


def get_active_window_title() -> str:
    """获取当前前台窗口标题。"""
    try:
        hwnd = ctypes.windll.user32.GetForegroundWindow()
        length = ctypes.windll.user32.GetWindowTextLengthW(hwnd)
        buf = ctypes.create_unicode_buffer(length + 1)
        ctypes.windll.user32.GetWindowTextW(hwnd, buf, length + 1)
        return buf.value
    except Exception:
        return ""


def is_claude_active() -> bool:
    """判断当前前台窗口是否为 Claude Code 相关窗口（用户正在看 CLI，无需弹窗）。"""
    title = get_active_window_title().lower()
    claude_keywords = [
        "claude code", "claude", ".claude",
    ]
    terminal_keywords = [
        "powershell", "cmd.exe", "windows terminal",
        "terminal", "命令提示符", "tabby", "wezterm", "alacritty",
    ]
    for kw in claude_keywords:
        if kw in title:
            return True
    for kw in terminal_keywords:
        if kw in title:
            return True
    return False


def notify_plyer(title: str, message: str, timeout: int) -> bool:
    try:
        from plyer import notification
        notification.notify(
            title=title,
            message=message,
            app_name="Claude Code",
            timeout=timeout,
        )
        return True
    except Exception:
        return False


def notify_powershell(title: str, message: str) -> bool:
    """Windows Toast fallback，无需额外依赖。"""
    try:
        ps_script = (
            "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications,"
            " ContentType = WindowsRuntime] > $null\n"
            "$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(\n"
            "    [Windows.UI.Notifications.ToastTemplateType]::ToastText02\n"
            ")\n"
            '$texts = $template.GetElementsByTagName("text")\n'
            f"$texts.Item(0).AppendChild($template.CreateTextNode('{title}')) > $null\n"
            f"$texts.Item(1).AppendChild($template.CreateTextNode('{message}')) > $null\n"
            "$toast = [Windows.UI.Notifications.ToastNotification]::new($template)\n"
            '$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")\n'
            "$notifier.Show($toast)\n"
        )
        subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_script],
            capture_output=True, timeout=10,
        )
        return True
    except Exception:
        return False


def main() -> None:
    parser = argparse.ArgumentParser(description="Claude Code 桌面通知工具")
    parser.add_argument("message", nargs="+", help="通知正文")
    parser.add_argument("--type", default="default",
                        choices=["permission", "notification", "stop", "default"],
                        help="通知类型，决定标题和超时")
    args = parser.parse_args()

    # 用户正在看 CLI 界面时不弹窗打扰
    if is_claude_active():
        return

    config = TYPE_CONFIG.get(args.type, TYPE_CONFIG["default"])
    message = " ".join(args.message)

    if not notify_plyer(config["title"], message, config["timeout"]):
        notify_powershell(config["title"], message)


if __name__ == "__main__":
    main()
