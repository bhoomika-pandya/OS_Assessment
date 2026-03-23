#!/bin/bash

# University Data Centre Process and Resource Management System
# This script provides system administration tools for process monitoring,
# disk management, and log control.

LOG_FILE="system_monitor_log.txt"

# Function to log actions with timestamps
log_action() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $message" >> "$LOG_FILE"
}
