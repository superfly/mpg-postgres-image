#!/bin/bash
set -e

# For Percona PostgreSQL Operator, we need to focus on protecting the postmaster process
ORIGINAL_ENTRYPOINT="/opt/crunchy/bin/postgres-ha/bootstrap-postgres-ha.sh"

# Try to set OOM score adjustment if possible, but don't fail if we can't
if command -v sudo >/dev/null 2>&1; then
  # If sudo is available, use it to set OOM score
  sudo -n sh -c 'echo -900 > /proc/self/oom_score_adj' >/dev/null 2>&1 || true
  echo "Attempted to set OOM score adjustment using sudo"
elif command -v setcap >/dev/null 2>&1; then
  # Try to give the oom-adjuster script the capability to adjust OOM scores
  setcap 'cap_sys_resource=+ep' /usr/local/bin/postgres-oom-adjuster.sh >/dev/null 2>&1 || true
  echo "Attempted to grant capabilities to OOM adjuster"
fi

# Start a background process to monitor and adjust PostgreSQL if possible
nohup /usr/local/bin/postgres-oom-adjuster.sh >> /tmp/postgres-oom-adjuster.log 2>&1 &
echo "Started postmaster OOM adjuster in background"

# Execute the original entrypoint
echo "Executing original entrypoint: $ORIGINAL_ENTRYPOINT $@"
exec "$ORIGINAL_ENTRYPOINT" "$@"
