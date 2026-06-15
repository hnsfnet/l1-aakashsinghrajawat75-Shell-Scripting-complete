#!/bin/bash
# Learning background jobs and concurrent task management
# Usage: bash 01_background_jobs.sh [seconds1 seconds2 ...]
# Example: bash 01_background_jobs.sh 1 3 2  (starts 3 concurrent sleep tasks)

# ── 1. Determine task list (use defaults if no arguments) ─────────────────
if [ $# -eq 0 ]; then
    # No arguments: run a short default demo so the script never does nothing
    TASKS=(2)
    echo "No arguments provided, running default demo (1 task: 2s)..."
else
    TASKS=("$@")
fi

# ── 2. Validate all parameters BEFORE launching anything ──────────────────
for i in "${!TASKS[@]}"; do
    val="${TASKS[$i]}"
    # Must be a positive integer (digits only, no leading minus, not zero)
    if ! [[ "$val" =~ ^[0-9]+$ ]] || [ "$val" -le 0 ]; then
        echo "Error: invalid argument '${val}' — all values must be positive integers (e.g. 1, 2, 5)." >&2
        exit 1
    fi
done

# ── 3. Launch background tasks concurrently ────────────────────────────────
TOTAL=${#TASKS[@]}
echo "Starting ${TOTAL} background task(s) concurrently..."
echo "--------------------------------------------"

PIDS=()
SECONDS_START=$SECONDS  # built-in bash timer (seconds since shell started)

for i in "${!TASKS[@]}"; do
    idx=$((i + 1))
    secs="${TASKS[$i]}"
    sleep "$secs" &
    pid=$!
    PIDS+=("$pid")
    echo "[Task ${idx}/${TOTAL}] sleep ${secs}s  started  (PID: ${pid})"
done

echo "--------------------------------------------"
echo "All tasks launched. Waiting for each to finish..."
echo ""

# ── 4. Wait for each task individually and report completion ───────────────
SUCCESS=0
for i in "${!PIDS[@]}"; do
    idx=$((i + 1))
    pid="${PIDS[$i]}"
    if wait "$pid"; then
        echo "[Task ${idx}/${TOTAL}] PID ${pid} completed successfully."
        SUCCESS=$((SUCCESS + 1))
    else
        echo "[Task ${idx}/${TOTAL}] PID ${pid} failed (exit code: $?)."
    fi
done

# ── 5. Summary ─────────────────────────────────────────────────────────────
ELAPSED=$((SECONDS - SECONDS_START))

echo ""
echo "============================================"
echo "  Summary"
echo "============================================"
echo "  Total tasks : ${TOTAL}"
echo "  Succeeded   : ${SUCCESS}"
echo "  Failed      : $((TOTAL - SUCCESS))"
echo "  Total time  : ${ELAPSED}s"
echo "============================================"
