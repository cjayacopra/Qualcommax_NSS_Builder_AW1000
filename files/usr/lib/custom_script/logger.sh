#!/bin/sh

LOG_FILE="/tmp/custom_script.log"

# Ensure /tmp exists and is writable
[ ! -d "/tmp" ] && mkdir -p "/tmp"

# Initialize log file with proper error handling
if ! touch "$LOG_FILE" 2>/dev/null; then
    echo "Error: Cannot create log file at $LOG_FILE"
    exit 1
fi

# Set proper permissions
chmod 644 "$LOG_FILE" 2>/dev/null

log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp: $1" >> "$LOG_FILE"
    # Ensure log doesn't grow too large (keep last 1000 lines)
    if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt 1000 ]; then
        tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
}
