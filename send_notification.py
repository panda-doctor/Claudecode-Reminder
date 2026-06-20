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
