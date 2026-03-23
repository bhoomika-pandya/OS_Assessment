#!/usr/bin/env python3
"""
University High Performance Computing Job Scheduler
This script manages computational job requests and processes them using
Round Robin or Priority Scheduling algorithms.
"""

import os
import sys
from datetime import datetime
from typing import List, Dict

# File paths for persistent storage
JOB_QUEUE_FILE = "job_queue.txt"
COMPLETED_JOBS_FILE = "completed_jobs.txt"
SCHEDULER_LOG_FILE = "scheduler_log.txt"

def log_event(message: str) -> None:
    """Log scheduling events with timestamp to the scheduler log file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(SCHEDULER_LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"{timestamp} | {message}\n")

