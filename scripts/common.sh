#!/bin/bash

# Find the project directory, regardless of where the script is run.
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Define the log file.
LOG_FILE="$PROJECT_DIR/logs/onboarding.log"

# Create the log directory if needed.
mkdir -p "$PROJECT_DIR/logs"

# Write a message to the log.
log_action() {
    printf '%s - %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$*" |
        tee -a "$LOG_FILE"
}

# Log an error and stop the script.
error_exit() {
    log_action "ERROR: $*"
    exit 1
}

# Require administrator privileges.
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "Please run this script using sudo." >&2
        exit 1
    fi
}

# Create a group only if it does not already exist.
create_group() {
    local group="$1"

    if getent group "$group" >/dev/null; then
        log_action "Group already exists: $group"
    else
        groupadd "$group" ||
            error_exit "Could not create group: $group"

        log_action "Created group: $group"
    fi
}

# Configure and validate sudo access for the ops group.
configure_ops_sudo() {
    local sudoers_file="/etc/sudoers.d/ops-onboarding"
    local temp_file

    # Create the temporary file inside the sudoers directory.
    temp_file="$(mktemp /etc/sudoers.d/ops-onboarding.XXXXXX)" ||
        error_exit "Could not create temporary sudoers file"

    # Remove the temporary file if this function fails.
    if ! printf '%s\n' '%ops ALL=(ALL:ALL) ALL' > "$temp_file"; then
        rm -f "$temp_file"
        error_exit "Could not write sudoers rule"
    fi

    chmod 0440 "$temp_file"

    # Validate the temporary file before installing it.
    if ! visudo -cf "$temp_file"; then
        rm -f "$temp_file"
        error_exit "Invalid sudoers configuration"
    fi

    # Install with secure ownership and permissions.
    if ! install -o root -g root -m 0440 \
        "$temp_file" "$sudoers_file"; then
        rm -f "$temp_file"
        error_exit "Could not install ops sudoers file"
    fi

    rm -f "$temp_file"

    # Validate the installed file and the complete sudo configuration.
    visudo -cf "$sudoers_file" ||
        error_exit "Installed ops sudoers file is invalid"

    visudo -c ||
        error_exit "Overall sudo configuration validation failed"

    log_action "Validated sudo access configuration for ops group"
}
