#!/bin/bash
set -Eeuo pipefail

# Load shared functions and settings.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

check_root

# Use the supplied CSV or the project's default CSV.
CSV_FILE="${1:-$PROJECT_DIR/data/users.csv}"

[[ -r "$CSV_FILE" ]] ||
    error_exit "Cannot read CSV file: $CSV_FILE"

# Check required commands before starting.
for cmd in useradd usermod passwd chage install visudo; do
    command -v "$cmd" >/dev/null 2>&1 ||
        error_exit "Required command not found: $cmd"
done

# Create required groups.
create_group dev
create_group qa
create_group ops

# Create shared team directories with setgid permissions.
for team in dev qa ops; do
    install -d -o root -g "$team" -m 2770 "/projects/$team" ||
        error_exit "Could not configure /projects/$team"

    log_action "Configured /projects/$team"
done

# Read the CSV file.
line_number=0
ops_needed=false

while IFS=, read -r username full_name team role || [[ -n "${username:-}" ]]; do
    ((line_number += 1))

    # Skip the header.
    if [[ "$line_number" -eq 1 ]]; then
        [[ "$username" == "username" ]] ||
            error_exit "Incorrect CSV header"
        continue
    fi

    # Skip blank lines.
    [[ -z "${username//[[:space:]]/}" ]] && continue

    # Remove surrounding whitespace.
    username="$(echo "$username" | xargs)"
    full_name="$(echo "$full_name" | xargs)"
    team="$(echo "$team" | xargs)"
    role="$(echo "$role" | xargs)"

    # Validate the username.
    [[ "$username" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] ||
        error_exit "Invalid username on CSV line $line_number"

    [[ -n "$full_name" && "$full_name" != *:* ]] ||
        error_exit "Invalid full name for $username"

    # Validate team and role.
    case "$team" in
        dev|qa|ops) ;;
        *) error_exit "Invalid team: $team" ;;
    esac

    case "$role" in
        developer|ops) ;;
        *) error_exit "Invalid role: $role" ;;
    esac

    if [[ "$role" == "ops" ]]; then
        [[ "$team" == "ops" ]] ||
            error_exit "Ops role must belong to ops team: $username"

        ops_needed=true
    fi

    # Do not modify an existing account.
    if id "$username" >/dev/null 2>&1; then
        log_action "User already exists; skipping: $username"
        continue
    fi

    # Create user with a home directory and primary team group.
    useradd -m -s /bin/bash -g "$team" \
        -c "$full_name" "$username" ||
        error_exit "Could not create user: $username"

    log_action "Created user $username with primary group $team"

    # Set a temporary password interactively.
    # Password input is not saved in the log.
    echo "Set a temporary password for $username."
    passwd "$username" </dev/tty ||
        error_exit "Could not set password for $username"

    # Force a password change at the next password-based login.
    chage -d 0 "$username" ||
        error_exit "Could not set password expiry for $username"

    log_action "Temporary password set; first-login change required for $username"

    # Add ops users to the ops group.
    if [[ "$role" == "ops" ]]; then
        usermod -aG ops "$username" ||
            error_exit "Could not add $username to ops group"

        log_action "Added $username to ops group"
    fi

done < "$CSV_FILE"

# Enable the approved sudoers policy if the CSV contains an ops role.
if [[ "$ops_needed" == true ]]; then
    configure_ops_sudo
fi

log_action "Onboarding process completed"
