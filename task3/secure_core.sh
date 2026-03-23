#!/usr/bin/env python3
"""
University Secure Examination System - Login Monitor
Handles student/admin login, failed attempt tracking, and account lockout.
Called by secure_core.sh with the submission log file path as argument.
"""

import sys
import os
import json
import hashlib
from datetime import datetime

# File paths
ACCOUNTS_FILE = "accounts.json"
LOGIN_LOG_FILE = "login_attempts.txt"
MAX_FAILED_ATTEMPTS = 3
LOCKOUT_DURATION_MINUTES = 30

def log_login_event(username: str, status: str, details: str) -> None:
    """Log login events with timestamp."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOGIN_LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"{timestamp} | USER={username} | STATUS={status} | {details}\n")


def hash_password(password: str) -> str:
    """Hash a password using SHA-256."""
    return hashlib.sha256(password.encode()).hexdigest()


def load_accounts() -> dict:
    """Load accounts from the accounts file."""
    if not os.path.exists(ACCOUNTS_FILE):
        return {}
    try:
        with open(ACCOUNTS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {}

