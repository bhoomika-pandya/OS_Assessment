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
