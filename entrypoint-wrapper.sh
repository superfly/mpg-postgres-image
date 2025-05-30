#!/bin/bash
set -e

# For Percona PostgreSQL Operator, we need to focus on protecting the postmaster process
# Original user in the Percona PostgreSQL Operator image
ORIGINAL_USER=26
ORIGINAL_ENTRYPOINT="/opt/crunchy/bin/postgres-ha/bootstrap-postgres-ha.sh"

# Set OOM score adjustment for our own process (will be inherited)
if [ -f "/proc/self/oom_score_adj" ]; then
    echo -900 > /proc/self/oom_score_adj
    echo "Set OOM score adjustment to -900 for pid 1"
else
    echo "WARNING: Cannot set OOM score adjustment (file not found)"
fi

# Start the OOM adjuster in the background
nohup /usr/local/bin/postgres-oom-adjuster.sh >> /tmp/postgres-oom-adjuster.log 2>&1 &
echo "Started postmaster OOM adjuster in background"

# Set environment variables for PostgreSQL child processes
export PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj
export PG_OOM_ADJUST_VALUE=0

# Switching to the original user and executing original entrypoint
echo "Switching to user $ORIGINAL_USER and executing original entrypoint: $ORIGINAL_ENTRYPOINT $@"

# Check which user-switching command is available
if command -v runuser >/dev/null 2>&1; then
    # Use runuser (available on RHEL/CentOS/Fedora)
    exec runuser -u "#$ORIGINAL_USER" -- "$ORIGINAL_ENTRYPOINT" "$@"
else
    # Fall back to su
    exec su -s /bin/bash $ORIGINAL_USER -c "$ORIGINAL_ENTRYPOINT $*"
fi
