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


def is_account_locked(account: dict) -> bool:
    """Check if an account is currently locked out."""
    if account.get("failed_attempts", 0) >= MAX_FAILED_ATTEMPTS:
        lockout_time_str = account.get("lockout_time")
        if lockout_time_str:
            lockout_time = datetime.strptime(lockout_time_str, "%Y-%m-%d %H:%M:%S")
            elapsed = (datetime.now() - lockout_time).total_seconds() / 60
            if elapsed < LOCKOUT_DURATION_MINUTES:
                remaining = int(LOCKOUT_DURATION_MINUTES - elapsed)
                return True, remaining
            else:
                # Lockout expired, reset
                return False, 0
    return False, 0


def get_lockout_status(account: dict):
    """Return (is_locked: bool, minutes_remaining: int)."""
    if account.get("failed_attempts", 0) >= MAX_FAILED_ATTEMPTS:
        lockout_time_str = account.get("lockout_time")
        if lockout_time_str:
            lockout_time = datetime.strptime(lockout_time_str, "%Y-%m-%d %H:%M:%S")
            elapsed = (datetime.now() - lockout_time).total_seconds() / 60
            if elapsed < LOCKOUT_DURATION_MINUTES:
                remaining = int(LOCKOUT_DURATION_MINUTES - elapsed)
                return True, remaining
            else:
                return False, 0
    return False, 0


def create_account(accounts: dict) -> None:
    """Create a new student or admin account."""
    print("\n  --- Create New Account ---")
    username = input("  Enter username (Student ID or admin name): ").strip()

    if not username:
        print("  Error: Username cannot be empty.")
        return

    if username in accounts:
        print(f"  Error: Account '{username}' already exists.")
        return

    role = input("  Role (student/admin) [default: student]: ").strip().lower()
    if role not in ("student", "admin"):
        role = "student"

    password = input("  Set password: ").strip()
    if not password:
        print("  Error: Password cannot be empty.")
        return

    confirm = input("  Confirm password: ").strip()
    if password != confirm:
        print("  Error: Passwords do not match.")
        return

    accounts[username] = {
        "role": role,
        "password_hash": hash_password(password),
        "failed_attempts": 0,
        "lockout_time": None,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "last_login": None
    }

    save_accounts(accounts)
    print(f"\n  Account '{username}' ({role}) created successfully.")
    log_login_event(username, "ACCOUNT_CREATED", f"New {role} account registered")
