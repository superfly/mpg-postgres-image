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
        else
            echo "$(date): Postmaster PID $POSTMASTER_PID already has OOM score -900" >> $LOG_FILE
        fi
    else
        echo "$(date): Postmaster not found yet or OOM score file not accessible" >> $LOG_FILE
    fi

    # Sleep for a while before checking again
    sleep 30
done
