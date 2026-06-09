#!/bin/bash
set -e

# OOM protection wrapper for patroni.
#
# The Percona Operator sets command=["patroni", "/etc/patroni"] on the pod spec,
# bypassing the Docker ENTRYPOINT. By placing this script at /usr/bin/patroni
# and renaming the real binary to /usr/bin/patroni-real, we intercept the call.
#
# NOTE: Writing to oom_score_adj requires CAP_SYS_RESOURCE or running as root.
# If the pod security context runs as UID 26, the echo below will fail silently.
# To make OOM protection effective, grant the container CAP_SYS_RESOURCE or
# run an init container that sets /proc/1/oom_score_adj for the pod.

if [ -f "/proc/self/oom_score_adj" ]; then
    echo -900 > /proc/self/oom_score_adj 2>/dev/null || true
fi

nohup /usr/local/bin/postgres-oom-adjuster.sh >> /tmp/postgres-oom-adjuster.log 2>&1 &

export PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj
export PG_OOM_ADJUST_VALUE=0

exec /usr/bin/patroni-real "$@"
