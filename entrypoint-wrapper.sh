#!/bin/bash
set -e

# For Percona PostgreSQL Operator, we need to focus on protecting the postmaster process
# Original user in the Percona PostgreSQL Operator image
ORIGINAL_USER=26 # (postgres user)

# Ensure a command was provided
if [ $# -eq 0 ]; then
    echo "ERROR: No command provided to entrypoint-wrapper.sh"
    echo "Usage: entrypoint-wrapper.sh <command> [args...]"
    exit 1
fi

# Set OOM score adjustment for our own process (will be inherited)
if [ -f "/proc/self/oom_score_adj" ]; then
    if echo -900 > /proc/self/oom_score_adj 2>/dev/null; then
        echo "Set OOM score adjustment to -900 for pid 1"
    else
        # If we fail, let the postgres oom adjuster handle it.
        echo "WARNING: Cannot set OOM score adjustment (will retry via background adjuster)"
    fi
else
    echo "WARNING: Cannot set OOM score adjustment (file not found)"
fi

# Start the OOM adjuster in the background
nohup /usr/local/bin/postgres-oom-adjuster.sh >> /tmp/postgres-oom-adjuster.log 2>&1 &
echo "Started postmaster OOM adjuster in background"

# Set environment variables for PostgreSQL child processes
export PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj
export PG_OOM_ADJUST_VALUE=0

# Switching to the original user and executing command
echo "Switching to user $ORIGINAL_USER and executing: $@"

# Check which user-switching command is available
if command -v runuser >/dev/null 2>&1; then
    # Use runuser (available on RHEL/CentOS/Fedora)
    exec runuser -u "#$ORIGINAL_USER" -- "$@"
else
    # Fall back to su
    exec su -s /bin/bash $ORIGINAL_USER -c "$*"
fi
