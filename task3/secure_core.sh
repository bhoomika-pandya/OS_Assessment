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
