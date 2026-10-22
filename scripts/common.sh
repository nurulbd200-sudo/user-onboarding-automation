#!/bin/bash

# Find the project root directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Define the log file path
LOG_FILE="$PROJECT_DIR/logs/onboarding.log"

# Write messages to the log file
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Stop the script if something goes wrong
error_exit() {
    log_action "ERROR: $1"
    exit 1
}

# Check if script is running as root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "Please run with sudo: sudo $0" >&2
        exit 1
    fi
}

# Create a group if it does not exist
create_group() {
    local group="$1"

    if getent group "$group" > /dev/null; then
        log_action "Group already exists: $group"
    else
        groupadd "$group" || error_exit "Failed to create group: $group"
        log_action "Created group: $group"
    fi
}
