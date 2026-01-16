#!/bin/bash

# This script runs in the background to find and adjust the PostgreSQL postmaster process
# It keeps running to catch the process if it starts after container initialization

LOG_FILE="/tmp/postgres-oom-adjuster.log"
echo "$(date): PostgreSQL OOM adjuster starting" >> $LOG_FILE

sleep 5

while true; do
    # Try various ways to find the postmaster process
    POSTMASTER_PID=""

    # Method 1: Look for postgres process with -D /pgdata/pg16
    if [ -z "$POSTMASTER_PID" ]; then
        POSTMASTER_PID=$(ps aux | grep "postgres -D /pgdata/pg" | grep -v grep | awk '{print $2}' | head -1)
        if [ -n "$POSTMASTER_PID" ]; then
            echo "$(date): Found postmaster using 'postgres -D /pgdata/pg' pattern: PID $POSTMASTER_PID" >> $LOG_FILE
        fi
    fi

    # Method 2: Look for postgres process that is a parent of other postgres processes
    if [ -z "$POSTMASTER_PID" ]; then
        for pid in $(pgrep -x postgres); do
            if [ "$(ps -o ppid= -p $(pgrep -x postgres | grep -v $pid) | grep $pid | wc -l)" -gt 0 ]; then
                POSTMASTER_PID=$pid
                echo "$(date): Found postmaster using parent-child relationship: PID $POSTMASTER_PID" >> $LOG_FILE
                break
            fi
        done
    fi

    # Method 3: If we only have one postgres process, assume it's the postmaster
    if [ -z "$POSTMASTER_PID" ] && [ "$(pgrep -x postgres | wc -l)" -eq 1 ]; then
        POSTMASTER_PID=$(pgrep -x postgres)
        echo "$(date): Only one postgres process found, assuming it's the postmaster: PID $POSTMASTER_PID" >> $LOG_FILE
    fi

    # If we found the postmaster, adjust its OOM score
    if [ -n "$POSTMASTER_PID" ] && [ -f "/proc/$POSTMASTER_PID/oom_score_adj" ]; then
        CURRENT_SCORE=$(cat /proc/$POSTMASTER_PID/oom_score_adj)
        if [ "$CURRENT_SCORE" != "-900" ]; then
            echo -900 > /proc/$POSTMASTER_PID/oom_score_adj
            echo "$(date): Adjusted OOM score for postmaster PID $POSTMASTER_PID from $CURRENT_SCORE to -900" >> $LOG_FILE
        fi
    else
        # Band-aid for the Postmaster PID problem. Actual fix is in Patroni >= 4.0.6.
        # Ref.: https://github.com/patroni/patroni/pull/3372
        echo "$(date): Postmaster not found, checking for orphaned shared memory" >> $LOG_FILE

        # Clean up orphaned POSIX shared memory segments
        # These block PostgreSQL startup if left behind after a crash
        if [ -d "/dev/shm" ]; then
            for shm_file in /dev/shm/PostgreSQL.*; do
                if [ -f "$shm_file" ]; then
                    echo "$(date): Removing orphaned POSIX shared memory: $shm_file" >> $LOG_FILE
                    rm -f "$shm_file" 2>/dev/null
                fi
            done
        fi

        # Clean up orphaned System V shared memory segments (nattch=0 means no attached processes)
        if command -v ipcs >/dev/null 2>&1 && command -v ipcrm >/dev/null 2>&1; then
            for shmid in $(ipcs -m 2>/dev/null | awk 'NR>3 && $6==0 {print $2}'); do
                if [ -n "$shmid" ]; then
                    echo "$(date): Removing orphaned SysV shared memory segment: $shmid" >> $LOG_FILE
                    ipcrm -m "$shmid" 2>/dev/null
                fi
            done
        fi
    fi

    # Sleep for a while before checking again
    sleep 30
done
