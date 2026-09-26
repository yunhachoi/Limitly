#!/usr/bin/env python3
"""Redacted local probe for the Codex app-server handshake."""

import json
import os
import subprocess
import sys
import time
from pathlib import Path


def locate() -> str:
    application_roots = [
        Path("/Applications/Codex.app"),
        Path.home() / "Applications" / "Codex.app",
    ]
    for application_root in application_roots:
        candidates = sorted(
            (
                path
                for path in application_root.rglob("codex")
                if path.is_file() and os.access(path, os.X_OK)
            ),
            key=lambda path: (len(str(path)), str(path)),
        )
        if candidates:
            return str(candidates[0])

    for entry in os.environ.get("PATH", "").split(":"):
        candidate = Path(entry) / "codex"
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    raise SystemExit("codex executable not found")


def send(process: subprocess.Popen, message: dict) -> None:
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()


def read_until_id(process: subprocess.Popen, request_id: int, deadline: float) -> dict:
    while time.monotonic() < deadline:
        line = process.stdout.readline()
        if not line:
            break
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue
        if message.get("id") == request_id:
            return message
    raise RuntimeError(f"no response for request {request_id}")


codex = locate()
process = subprocess.Popen(
    [codex, "app-server", "--stdio"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True,
    bufsize=1,
)

try:
    deadline = time.monotonic() + 10
    send(process, {"method": "initialize", "id": 1, "params": {"clientInfo": {"name": "limitly-probe", "title": "Limitly", "version": "1.0.0"}}})
    init = read_until_id(process, 1, deadline)
    print({"initialize": "ok" if "result" in init else "error"})

    send(process, {"method": "initialized", "params": {}})
    send(process, {"method": "account/read", "id": 2, "params": {"refreshToken": False}})
    account = read_until_id(process, 2, deadline)
    account_result = account.get("result") or {}
    account_info = account_result.get("account") if isinstance(account_result, dict) else None
    print({"account": account_info.get("type") if isinstance(account_info, dict) else None, "requiresOpenaiAuth": account_result.get("requiresOpenaiAuth") if isinstance(account_result, dict) else None})

    send(process, {"method": "account/rateLimits/read", "id": 3})
    limits = read_until_id(process, 3, deadline)
    if "error" in limits:
        print({"rateLimits": "error", "message": limits["error"].get("message")})
    else:
        result = limits.get("result") or {}
        by_id = result.get("rateLimitsByLimitId") or {}
        windows = {}
        for limit_id, bucket in by_id.items():
            if not isinstance(bucket, dict):
                continue
            windows[limit_id] = {
                key: {
                    "usedPercent": value.get("usedPercent"),
                    "windowDurationMins": value.get("windowDurationMins"),
                }
                for key in ("primary", "secondary")
                if isinstance(value := bucket.get(key), dict)
            }
        print({"rateLimitIds": sorted(by_id.keys()), "windows": windows, "hasLegacyRateLimits": bool(result.get("rateLimits"))})
finally:
    if process.stdin:
        process.stdin.close()
    process.terminate()
    process.wait(timeout=3)
