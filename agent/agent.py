"""
Company Systems Agent
- هر ۱۰ ثانیه heartbeat می‌فرسته (CPU/RAM/Uptime واقعی)
- هر ۵ ثانیه دنبال دستورات جدید می‌گرده
- دستور shutdown/restart رو اجرا می‌کنه

اجرا:  python agent.py --system-id 1 --server http://127.0.0.1:8000
"""
import argparse
import os
import platform
import subprocess
import sys
import time
from datetime import datetime

import psutil
import requests

HEARTBEAT_INTERVAL = 10  # ثانیه
COMMAND_POLL_INTERVAL = 5  # ثانیه


def get_uptime() -> str:
    secs = time.time() - psutil.boot_time()
    days = int(secs // 86400)
    hours = int((secs % 86400) // 3600)
    return f"{days}d {hours}h"


def get_cpu() -> str:
    return f"{psutil.cpu_percent(interval=0.5):.0f}%"


def get_ram() -> str:
    m = psutil.virtual_memory()
    used = m.used / (1024 ** 3)
    total = m.total / (1024 ** 3)
    return f"{used:.1f} GB / {total:.0f} GB"


def send_heartbeat(server: str, system_id: str):
    try:
        requests.post(
            f"{server}/heartbeat",
            json={
                "system_id": system_id,
                "cpu": get_cpu(),
                "ram": get_ram(),
                "uptime": get_uptime(),
            },
            timeout=5,
        )
        print(f"[{datetime.now():%H:%M:%S}] 💓 heartbeat sent")
    except Exception as e:
        print(f"[{datetime.now():%H:%M:%S}] ⚠️  heartbeat failed: {e}")


def poll_commands(server: str, system_id: str):
    try:
        res = requests.get(
            f"{server}/agent/{system_id}/commands", timeout=5
        )
        if res.status_code != 200:
            return
        cmds = res.json()
        for c in cmds:
            print(f"[{datetime.now():%H:%M:%S}] 🎯 executing command #{c['id']}: {c['action']}")
            execute_command(server, c["id"], c["action"])
    except Exception as e:
        print(f"[{datetime.now():%H:%M:%S}] ⚠️  poll failed: {e}")


def execute_command(server: str, cmd_id: int, action: str):
    status = "done"
    result = ""
    try:
        if action == "shutdown":
            print(">>> SHUTTING DOWN SYSTEM...")
            if sys.platform.startswith("win"):
                # ۶۰ ثانیه مهلت — قابل لغو با shutdown /a
                subprocess.Popen(["shutdown", "/s", "/t", "60", "/c", "Remote shutdown via Company Systems"])
                result = "Shutdown scheduled (60s delay)"
            else:
                # لینوکس: نیاز به sudo. اگه agent با sudo اجرا شه کار می‌کنه.
                subprocess.Popen(["sudo", "shutdown", "-h", "+1"])
                result = "Shutdown scheduled (+1 min)"
        elif action == "restart":
            print(">>> RESTARTING SYSTEM...")
            if sys.platform.startswith("win"):
                subprocess.Popen(["shutdown", "/r", "/t", "60", "/c", "Remote restart"])
                result = "Restart scheduled (60s delay)"
            else:
                subprocess.Popen(["sudo", "shutdown", "-r", "+1"])
                result = "Restart scheduled (+1 min)"
        else:
            status = "failed"
            result = f"Unknown action: {action}"
    except Exception as e:
        status = "failed"
        result = str(e)

    # ارسال ack
    try:
        requests.post(
            f"{server}/agent/commands/{cmd_id}/ack",
            json={"command_id": cmd_id, "status": status, "result": result},
            timeout=5,
        )
        print(f"[{datetime.now():%H:%M:%S}] ✅ command #{cmd_id} {status}: {result}")
    except Exception as e:
        print(f"⚠️  ack failed: {e}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--system-id", required=True, help="System ID (e.g., 1)")
    parser.add_argument("--server", default="http://127.0.0.1:8000", help="Backend URL")
    args = parser.parse_args()

    print(f"🤖 Agent starting for system '{args.system_id}'")
    print(f"📡 Server: {args.server}")
    print(f"💻 OS: {platform.platform()}")
    print(f"🆔 Hostname: {platform.node()}")
    print()

    last_hb = 0
    last_poll = 0

    try:
        while True:
            now = time.time()
            if now - last_hb >= HEARTBEAT_INTERVAL:
                send_heartbeat(args.server, args.system_id)
                last_hb = now
            if now - last_poll >= COMMAND_POLL_INTERVAL:
                poll_commands(args.server, args.system_id)
                last_poll = now
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n👋 Agent stopped.")


if __name__ == "__main__":
    main()
