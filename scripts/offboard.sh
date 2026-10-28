#!/bin/bash
set -Eeuo pipefail

# Load shared functions.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

check_root

# Get the username from the command line.
username="${1:-}"

# Require a username.
if [[ -z "$username" ]]; then
    echo "Usage: sudo $0 <username>"
    exit 1
fi

# Validate the username before using it in commands or paths.
[[ "$username" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] ||
    error_exit "Invalid username: $username"

# Never remove root or the administrator running this script.
[[ "$username" != "root" ]] ||
    error_exit "Refusing to remove root"

if [[ -n "${SUDO_USER:-}" && "$username" == "$SUDO_USER" ]]; then
    error_exit "Refusing to remove the account running this script"
fi

# Check that the user exists.
if ! getent passwd "$username" >/dev/null; then
    error_exit "User does not exist: $username"
fi

# Find the user's home directory.
home_dir="$(getent passwd "$username" | cut -d: -f6)"

[[ -n "$home_dir" && -d "$home_dir" ]] ||
    error_exit "Home directory not found for $username"

# Prepare a private directory for backups.
ARCHIVE_DIR="/var/backups/user-onboarding"

install -d -o root -g root -m 0700 "$ARCHIVE_DIR" ||
    error_exit "Could not create archive directory"

# Lock the account before archiving it.
passwd -l "$username" ||
    error_exit "Could not lock password for $username"

# Expire the account to prevent normal account login.
usermod --expiredate 1 "$username" ||
    error_exit "Could not expire account: $username"

log_action "Locked and expired account: $username"

# Create a unique archive name.
archive_file="$ARCHIVE_DIR/${username}_$(date '+%Y%m%d_%H%M%S').tar.gz"

[[ ! -e "$archive_file" ]] ||
    error_exit "Archive already exists: $archive_file"

# Archive the complete home directory before removing the account.
tar -czpf "$archive_file" -C "$(dirname "$home_dir")" \
    "$(basename "$home_dir")" ||
    error_exit "Archive failed; account was not removed: $username"

chmod 0600 "$archive_file"
log_action "Archived home directory to $archive_file"

# Remove the account and its home directory.
# The backup has already been created.
userdel -r "$username" ||
    error_exit "Account removal failed; backup retained: $username"

log_action "Removed user and home directory: $username"
log_action "Offboarding completed for $username"
