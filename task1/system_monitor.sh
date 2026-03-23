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


# Function to display current CPU and memory usage
show_cpu_memory() {
    echo ""
    echo "==== Current CPU and Memory Usage ===="
    echo ""
    
    # Display CPU information using wmic (Windows)
    echo "CPU Usage:"
    wmic cpu get Name,LoadPercentage /format:list 2>/dev/null | tr -d '\r' | grep -E "Name=|LoadPercentage="
    echo ""

    # Display memory information using PowerShell (handles encoding correctly)
    echo "Memory Usage:"
    powershell.exe -NoProfile -Command "
        \$os = Get-WmiObject Win32_OperatingSystem;
        \$total = [math]::Round(\$os.TotalVisibleMemorySize / 1MB, 1);
        \$free  = [math]::Round(\$os.FreePhysicalMemory / 1MB, 1);
        \$used  = [math]::Round(\$total - \$free, 1);
        Write-Host ('{0,-16} {1,8} {2,8} {3,8}' -f '', 'total', 'used', 'free');
        Write-Host ('{0,-16} {1,7}G {2,7}G {3,7}G' -f 'Mem:', \$total, \$used, \$free)
    " 2>/dev/null | tr -d '\r'
    echo ""
    
    log_action "Viewed CPU and memory usage statistics"
}


# Function to list top 10 memory consuming processes
list_top_memory_processes() {
    echo ""
    echo "==== Top 10 Memory Consuming Processes ===="
    echo ""
    printf "%-8s %-8s %-12s %s\n" "PID" "MEM_MB" "CPU_SEC" "PROCESS"
    echo "------------------------------------------------------------"
    powershell.exe -NoProfile -Command "
        \$procs = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10;
        foreach (\$p in \$procs) {
            \$mem = [math]::Round(\$p.WorkingSet64/1MB, 1);
            \$cpu = try { [math]::Round(\$p.TotalProcessorTime.TotalSeconds, 1) } catch { 0 };
            Write-Host (\$p.Id.ToString().PadRight(8) + \$mem.ToString().PadRight(10) + \$cpu.ToString().PadRight(14) + \$p.ProcessName)
        }
    " 2>/dev/null | tr -d '\r'
    echo ""
    
    log_action "Listed top 10 memory consuming processes"
}

# Function to terminate a selected process with safeguards
terminate_process() {
    echo ""
    read -p "Enter PID of process to terminate: " pid
    
    # Validate PID is a number
    if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid PID. Please enter a numeric process ID."
        log_action "Invalid PID entered: $pid"
        return
    fi
    
    # Check if process exists (Windows: use tasklist)
    proc_line=$(tasklist /FI "PID eq $pid" /FO CSV /NH 2>/dev/null | tr -d '\r' | grep -v "^$" | head -1)
    if [ -z "$proc_line" ] || echo "$proc_line" | grep -qi "No tasks"; then
        echo "Error: No process found with PID $pid."
        log_action "Process termination failed: PID $pid does not exist"
        return
    fi

    # Get process information from tasklist CSV output
    proc_name=$(echo "$proc_line" | cut -d',' -f1 | tr -d '"')
    proc_user=$(powershell.exe -NoProfile -Command "(Get-Process -Id $pid -ErrorAction SilentlyContinue).UserName" 2>/dev/null | tr -d '\r' || echo "N/A")
    
    # List of critical PIDs that should never be terminated
    critical_pids=(1)
    for cp in "${critical_pids[@]}"; do
        if [ "$pid" -eq "$cp" ]; then
            echo "Error: Cannot terminate critical system process (PID $pid)."
            echo "This is a protected process essential for system operation."
            log_action "BLOCKED: Attempted to terminate critical process PID $pid ($proc_name)"
            return
        fi
    done
    
    # List of critical process names that should never be terminated
    case "$proc_name" in
        init|systemd|kthreadd|rcu_sched|ksoftirqd|migration|watchdog|kworker)
            echo "Error: Cannot terminate critical system process '$proc_name'."
            echo "This process is essential for system operation."
            log_action "BLOCKED: Attempted to terminate critical process $proc_name (PID $pid)"
            return
            ;;
    esac
    
    # Display process details and request confirmation
    echo ""
    echo "Process Details:"
    echo "  PID: $pid"
    echo "  Name: $proc_name"
    echo "  User: $proc_user"
    echo ""
    
    read -p "Are you sure you want to terminate this process? (Y/N): " confirm
    
    case "$confirm" in
        [Yy]|[Yy][Ee][Ss])
            if taskkill /PID "$pid" /F > /dev/null 2>&1; then
                echo "Success: Process $pid ($proc_name) has been terminated."
                log_action "TERMINATED: Process PID $pid ($proc_name) by user"
            else
                echo "Error: Failed to terminate process $pid."
                echo "This may be due to insufficient permissions or the process already exited."
                log_action "FAILED: Could not terminate process PID $pid ($proc_name)"
            fi
            ;;
        [Nn]|[Nn][Oo])
            echo "Termination cancelled."
            log_action "CANCELLED: Termination of process PID $pid ($proc_name) cancelled by user"
            ;;
        *)
            echo "Invalid input. Termination cancelled."
            log_action "CANCELLED: Invalid confirmation input for PID $pid termination"
            ;;
    esac
    echo ""
}
