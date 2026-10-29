Automated User Onboarding and Access Setup

A Linux user management automation project built with Bash scripting to simplify user onboarding, access configuration, and offboarding on Ubuntu servers.

📌 Project Overview

Managing Linux users manually can be time-consuming and error-prone, especially when multiple employees join or leave an organization.

This project automates common user administration tasks using Bash scripts. It creates user accounts from a CSV file, configures team-based groups and directory permissions, manages privileged access, and securely offboards users while preserving backups.

The project demonstrates practical Linux system administration, scripting, access control, logging, and Git version control skills relevant to DevOps engineering.

🎯 Objectives
Automate Linux user creation and removal.
Manage users and groups based on team assignments.
Configure secure, team-based directory permissions.
Require users to change temporary passwords at first password-based login.
Configure sudo access for authorized operations users.
Support SSH public-key authentication.
Maintain logs of administrative actions.
Back up user home directories before offboarding.
Practice Git branching, merging, conflict resolution, and reverting commits.

🛠️ Technologies Used
Technology	Purpose
Ubuntu Linux	Operating system
Bash	Automation scripting
Linux user and group management	Account administration
SSH	Remote access and key-based authentication
Linux permissions	Access control
sudo and visudo	Privileged access management
tar	Home directory backups
Git and GitHub	Version control and collaboration

📁 Project Structure
user-onboarding-automation/
├── scripts/
│   ├── onboard.sh
│   ├── offboard.sh
│   └── common.sh
├── data/
│   └── users.csv
├── logs/
│   └── onboarding.log
└── README.md

File Descriptions
onboard.sh — Creates users, configures groups and team directories, and applies onboarding settings.
offboard.sh — Locks and expires user accounts, archives home directories, and removes accounts.
common.sh — Contains reusable functions for logging, privilege checks, group creation, and sudo configuration.
users.csv — Stores user information used by the onboarding script.
onboarding.log — Records administrative actions and relevant errors.

👥 User Input Configuration

The onboarding script reads user information from data/users.csv.

Example:

username,full_name,team,role
nurul01,Nurul Islam,dev,developer
saiful02,Saiful Islam,qa,developer
nafiz03,Nafiz Hossain,ops,ops

Each record contains:

username — Linux login name.
full_name — User's full name.
team — Team assignment: dev, qa, or ops.
role — Role used to determine applicable access, including operations privileges.

Note: Use unique usernames, valid team and role values, and appropriate authorization for privileged accounts.

⚙️ Features
1. Automated User Onboarding

The onboarding script:

Checks for administrator privileges.
Creates the dev, qa, and ops groups if they do not exist.
Creates user accounts with home directories and Bash login shells.
Assigns primary groups according to team membership.
Prompts the administrator to set temporary passwords for new users.
Requires a password change at the first password-based login.
Configures sudo access for authorized operations users.
Logs onboarding activities.

2. Team-Based Directory Permissions

The script creates the following directories:

/projects/dev
/projects/qa
/projects/ops

Each directory is configured with root ownership, the appropriate team group, and permissions of 2770.

Example:

sudo install -d -o root -g dev -m 2770 /projects/dev

The 2770 permission provides:

Owner: read, write, and execute.
Group: read, write, and execute.
Others: no access.
Setgid bit: new entries inherit the directory's group on typical Linux filesystems.

This supports team collaboration while restricting access to authorized users.

3. Privileged Access Management

Authorized operations users receive sudo access through a configuration file under /etc/sudoers.d/.

The script validates the configuration using visudo before relying on it.

Example validation:

sudo visudo -cf /etc/sudoers.d/ops-onboarding

Privileged access should be limited to users who require it and follow the principle of least privilege.

4. SSH Key-Based Authentication

The project supports configuring SSH public-key authentication for at least one onboarding user.

The public key is stored in the user's ~/.ssh/authorized_keys file, with appropriate ownership and permissions.

Example:

chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

The corresponding private key remains on the client machine and must never be committed to Git or shared.

5. Automated User Offboarding

The offboarding script:

Validates the username and confirms the account exists.
Locks password authentication and expires the account.
Archives the user's home directory.
Removes the user account and home directory.
Records the outcome in the log.

Backups are stored under:

/var/backups/user-onboarding/

Example command:

sudo ./scripts/offboard.sh nurul01

Offboarding should also include revoking SSH keys, other credentials, and active access paths as appropriate. Account locking alone does not necessarily terminate existing sessions.

6. Logging and Error Handling

The shared common.sh file provides reusable logging and error-handling functions.

The project log is located at:

logs/onboarding.log

Example log entry:

2026-10-29 10:30:00 - Created user nurul01 with primary group dev

Logs help administrators troubleshoot failures and review completed actions. Passwords and private keys must never be written to logs.

🚀 Getting Started
Prerequisites
An Ubuntu Linux server or virtual machine.
A user account with sudo privileges.
Bash and standard Linux administration utilities.
Git installed if using the version-control workflow.
An SSH client for remote-access testing.
Step 1: Clone the Repository
git clone https://github.com/nurulbd200-sudo/user-onboarding-automation.git
cd user-onboarding-automation
Step 2: Review the Input File
cat data/users.csv

Ensure the CSV contains valid usernames, teams, and roles.

Step 3: Make Scripts Executable
chmod +x scripts/onboard.sh scripts/offboard.sh
Step 4: Run the Onboarding Script
sudo ./scripts/onboard.sh

The script reads users from data/users.csv by default.

Step 5: Verify User and Group Configuration
id nurul01
getent group dev
getent passwd nurul01

Check the team directory permissions:

ls -ld /projects/dev /projects/qa /projects/ops

Review the log:

tail -n 20 logs/onboarding.log
Step 6: Test SSH Access

After configuring the user's public key and the server's network access, connect from the client machine:

ssh -i ~/.ssh/id_ed25519 nurul01@YOUR_SERVER_PUBLIC_IP

Replace YOUR_SERVER_PUBLIC_IP with the actual reachable server address.

Step 7: Test Offboarding

Warning: This removes the selected account and its home directory after attempting to create a backup. Use a test account and verify the archive before proceeding.

sudo ./scripts/offboard.sh nurul01

Verify the account status and backup:

id nurul01
sudo ls -lh /var/backups/user-onboarding/

An account-not-found response from id indicates that the account no longer exists.

🌿 Git Workflow

The project also provides practice with collaborative Git workflows.

Typical workflow:

git switch -c feature/onboarding
git add scripts/onboard.sh scripts/common.sh
git commit -m "Add user onboarding automation"

Create a separate branch for offboarding:

git switch -c feature/offboarding
git add scripts/offboard.sh
git commit -m "Add user offboarding automation"

Other practice tasks include:

Creating pull requests.
Resolving merge conflicts.
Reviewing changes with git diff.
Inspecting history with git log --oneline --graph.
Using git stash for temporary changes.
Using git revert to reverse a commit safely on a shared branch.

🔐 Security Considerations
Never commit passwords, private keys, or sensitive credentials.
Protect SSH private keys and restrict access to backup archives.
Validate sudoers configuration before applying privileged access.
Grant sudo privileges only when required.
Keep SSH network access restricted to trusted sources where practical.
Review ownership and permissions on user homes and SSH files.
Validate backups before deleting user data.
Review active sessions and other credentials during offboarding.
Test destructive operations on a non-production server first.

📚 Key Learnings

Through this project, I practiced:

Linux user and group administration.
Bash scripting, functions, variables, and error handling.
Automating repetitive system administration tasks.
File ownership, permissions, and setgid directories.
SSH public-key authentication.
Sudo access management and configuration validation.
Logging, backups, and account lifecycle management.
Git branching, merging, conflict resolution, and commit reversion.
Troubleshooting Linux shell and account-management errors.

🔮 Future Improvements
Add automated tests and shell linting with ShellCheck.
Improve CSV validation and handling of malformed input.
Add rollback or recovery handling for partially completed onboarding.
Make repeated onboarding runs consistently idempotent.
Integrate the scripts into a CI/CD pipeline.
Add structured logs, log rotation, and monitoring.
Implement configurable least-privilege sudo policies.
Add automated verification of SSH access and backup integrity.

💻 Author

Nurul Islam

DevOps learning project focused on Linux administration, Bash automation, access management, and Git workflows.

This project is intended for learning and testing in a controlled Linux environment. Review scripts and access policies before using them on production systems.
