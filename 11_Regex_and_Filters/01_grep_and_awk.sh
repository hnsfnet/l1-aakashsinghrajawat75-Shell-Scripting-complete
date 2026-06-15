#!/bin/bash
# =============================================================================
# filter.sh - A command-line text filtering tool
#
# Demonstrates the power of grep and awk as building blocks for a practical
# text processing pipeline. Supports file input, piped input, keyword
# filtering, column extraction, counting, and case-insensitive matching.
#
# Usage:
#   ./01_grep_and_awk.sh [OPTIONS] [FILE]
#
# Options:
#   --contains <pattern>   Filter lines that contain <pattern>
#   --ignore-case          Make --contains case-insensitive
#   --column <N>           Extract the Nth column (1-based, comma-separated)
#   --count                Print the number of result lines instead of content
#   -h, --help             Show this help message
#
# Examples:
#   # Find lines containing "apple" in a file
#   ./01_grep_and_awk.sh --contains apple fruits.txt
#
#   # Case-insensitive search via pipe
#   cat fruits.txt | ./01_grep_and_awk.sh --contains APPLE --ignore-case
#
#   # Extract the "Name" column (column 1) from a CSV
#   ./01_grep_and_awk.sh --column 1 users.csv
#
#   # Filter, extract, then count: how many users are aged 21?
#   ./01_grep_and_awk.sh --contains 21 --column 1 --count users.csv
# =============================================================================

# ---- Usage / help -----------------------------------------------------------
usage() {
    cat <<'USAGE'
Usage: 01_grep_and_awk.sh [OPTIONS] [FILE]

Options:
  --contains <pattern>   Filter lines that contain <pattern>
  --ignore-case          Make --contains case-insensitive
  --column <N>           Extract the Nth comma-separated column (1-based)
  --count                Print the number of result lines instead of content
  -h, --help             Show this help message

If FILE is omitted and stdin is not a terminal, input is read from stdin.
USAGE
}

# ---- Parse arguments --------------------------------------------------------
CONTAINS=""
IGNORE_CASE=0
COLUMN=""
COUNT=0
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --contains)
            # --contains requires a value; use shift arithmetic to peek safely
            if [[ $# -lt 2 ]]; then
                echo "Error: --contains requires a <pattern> argument." >&2
                usage >&2
                exit 1
            fi
            CONTAINS="$2"
            shift 2
            ;;
        --ignore-case)
            IGNORE_CASE=1
            shift
            ;;
        --column)
            if [[ $# -lt 2 ]]; then
                echo "Error: --column requires a positive integer argument." >&2
                usage >&2
                exit 1
            fi
            COLUMN="$2"
            shift 2
            ;;
        --count)
            COUNT=1
            shift
            ;;
        -*)
            echo "Error: unknown option '$1'." >&2
            usage >&2
            exit 1
            ;;
        *)
            # Positional argument: treat as input file
            if [[ -n "$INPUT_FILE" ]]; then
                echo "Error: unexpected extra argument '$1'." >&2
                usage >&2
                exit 1
            fi
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# ---- Validate arguments -----------------------------------------------------

# --column must be a positive integer
if [[ -n "$COLUMN" ]]; then
    if ! [[ "$COLUMN" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: --column value must be a positive integer (>= 1), got '$COLUMN'." >&2
        exit 1
    fi
fi

# --ignore-case only makes sense with --contains
if [[ "$IGNORE_CASE" -eq 1 && -z "$CONTAINS" ]]; then
    echo "Warning: --ignore-case has no effect without --contains." >&2
fi

# ---- Determine input source -------------------------------------------------
# If a file path was given, verify it exists and is readable.
# Otherwise, fall back to stdin — but only when stdin is a pipe / redirect.
if [[ -n "$INPUT_FILE" ]]; then
    if [[ ! -f "$INPUT_FILE" ]]; then
        echo "Error: file '$INPUT_FILE' does not exist." >&2
        exit 1
    fi
    if [[ ! -r "$INPUT_FILE" ]]; then
        echo "Error: file '$INPUT_FILE' is not readable." >&2
        exit 1
    fi
else
    # No file specified — check whether stdin has data (i.e. is not a terminal)
    if [[ -t 0 ]]; then
        echo "Error: no input file specified and nothing on stdin." >&2
        echo "" >&2
        usage >&2
        exit 1
    fi
fi

# ---- Build the processing pipeline ------------------------------------------
# We compose small stages — each one optional — using shell pipes, much like
# the way grep | awk is used in everyday shell scripting.

# Stage 0: read input (file or stdin)
read_input() {
    if [[ -n "$INPUT_FILE" ]]; then
        cat "$INPUT_FILE"
    else
        cat -   # read from stdin
    fi
}

# Stage 1: keyword filter (grep)
apply_grep() {
    if [[ -n "$CONTAINS" ]]; then
        if [[ "$IGNORE_CASE" -eq 1 ]]; then
            grep -i -- "$CONTAINS"
        else
            grep -- "$CONTAINS"
        fi
    else
        cat -   # pass-through when no filter
    fi
}

# Stage 2: column extraction (awk)
apply_awk() {
    if [[ -n "$COLUMN" ]]; then
        awk -F',' -v col="$COLUMN" '{
            if (col <= NF) {
                print $col
            }
        }'
    else
        cat -
    fi
}

# Stage 3: counting (wc -l) or pass-through
apply_count() {
    if [[ "$COUNT" -eq 1 ]]; then
        wc -l | tr -d '[:space:]'
        echo   # trailing newline
    else
        cat -
    fi
}

# ---- Run the pipeline -------------------------------------------------------
# Each stage feeds the next, demonstrating how small Unix tools compose.
read_input | apply_grep | apply_awk | apply_count

exit 0
