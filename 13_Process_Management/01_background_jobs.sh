#!/bin/bash
# Learning background jobs: a concurrent "wait" demo.
#
# Usage:
#   bash 01_background_jobs.sh [SECONDS ...]
#     e.g. bash 01_background_jobs.sh 1 3 2   -> run 3 sleep tasks in parallel
#
# With no arguments a short default demo runs (one 2-second task).
# Each SECONDS value must be a positive integer (1, 2, 3, ...).

# --- Step 1: decide which sleep durations to run ---
if [ "$#" -eq 0 ]; then
    echo "No arguments given, running the default demo (one 2-second task)."
    durations=(2)
else
    durations=("$@")
fi

# --- Step 2: validate every argument BEFORE starting any task ---
# We check first so that a bad argument never leaves stray processes running.
for value in "${durations[@]}"; do
    # A positive integer is a non-zero leading digit followed by more digits.
    if ! [[ "$value" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: '$value' is not a positive integer (use values like 1, 2, 3)." >&2
        exit 1
    fi
done

# --- Step 3: launch each sleep in the background and remember its PID ---
pids=()                 # holds the PID of every background task
total=${#durations[@]}
start_time=$SECONDS     # bash built-in: seconds since this shell started

echo "Starting $total background task(s)..."
index=1
for secs in "${durations[@]}"; do
    sleep "$secs" &     # '&' sends the command to the background
    pid=$!              # '$!' is the PID of the most recent background command
    pids+=("$pid")
    echo "  Task #$index: sleep ${secs}s  (PID: $pid)"
    index=$((index + 1))
done

# --- Step 4: wait for each task and report as soon as it finishes ---
# Because the tasks run concurrently, the total time is the LONGEST sleep,
# not the sum of all of them.
echo "Waiting for tasks to finish..."
completed=0
index=1
for pid in "${pids[@]}"; do
    if wait "$pid"; then
        echo "  Task #$index (PID: $pid) has completed."
        completed=$((completed + 1))
    else
        echo "  Task #$index (PID: $pid) failed." >&2
    fi
    index=$((index + 1))
done

# --- Step 5: print a summary ---
elapsed=$((SECONDS - start_time))
echo "----- Summary -----"
echo "Total tasks    : $total"
echo "Completed OK   : $completed"
echo "Total time (s) : $elapsed"
