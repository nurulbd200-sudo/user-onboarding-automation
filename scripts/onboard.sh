#!/bin/bash
set -e

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Require administrator privileges
check_root

# Locate CSV file
CSV_FILE="${1:-$PROJECT_DIR/data/users.csv}"

# Make sure the CSV exists
if [[ ! -f "$CSV_FILE" ]]; then
    error_exit "CSV file not found: $CSV_FILE"
fi

# Create required groups
create_group dev
create_group qa
create_group ops

# Create shared team directories
for team in dev qa ops; do
    install -d -o root -g "$team" -m 2770 "/projects/$team"
    log_action "Configured /projects/$team"
done

# Read users from CSV
while IFS=, read -r username full_name team role || [[ -n "$username" ]]; do

    # Skip the header and empty lines
    [[ "$username" == "username" || -z "$username" ]] && continue

    # Validate team
    case "$team" in
        dev|qa|ops) ;;
        *) error_exit "Invalid team: $team" ;;
    esac

    # Validate role
    case "$role" in
        developer|ops) ;;
        *) error_exit "Invalid role: $role" ;;
    esac

    # Check for existing user
    if id "$username" &>/dev/null; then
        log_action "User already exists; skipping: $username"
        continue
    fi

    # Create user with home directory and primary team group
    useradd -m -s /bin/bash -g "$team" -c "$full_name" "$username"
    log_action "Created user: $username (team: $team)"

    # Keep password locked until a temporary password is securely set
    passwd -l "$username" >/dev/null
    chage -d 0 "$username"
    log_action "Locked password pending secure setup: $username"

    # Add ops-role users to the ops group
    if [[ "$role" == "ops" ]]; then
        [[ "$team" == "ops" ]] ||
            error_exit "Ops role must belong to the ops team: $username"

        usermod -aG ops "$username"
        log_action "Added $username to ops group; sudo is not enabled yet"
    fi

done < "$CSV_FILE"

log_action "Onboarding completed"
