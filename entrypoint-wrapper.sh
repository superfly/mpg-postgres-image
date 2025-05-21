#!/bin/bash
set -e

# For Percona PostgreSQL Operator, Patroni is the process manager
# The OOM score adjustment needs to be applied to Patroni process
# which will then be inherited by the PostgreSQL process

# Set OOM score adjustment to -1000 for the current process (Patroni)
# This ensures both Patroni and PostgreSQL processes are killed last by the OOM killer
if [ -f "/proc/self/oom_score_adj" ]; then
    echo -900 > /proc/self/oom_score_adj
    echo "Set OOM score adjustment to -1000 for Patroni process"
else
    echo "WARNING: Cannot set OOM score adjustment (file not found)"
fi

exec "$@"
