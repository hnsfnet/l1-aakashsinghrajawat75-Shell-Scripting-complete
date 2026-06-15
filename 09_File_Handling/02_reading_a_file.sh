#!/bin/bash
# Reading a file line by line

# --- Defaults ---
file="data.txt"
number_lines=false
skip_empty=false

# --- Usage ---
usage() {
    echo "Usage: $0 [OPTIONS] [FILE]"
    echo ""
    echo "Read a text file line by line."
    echo ""
    echo "Options:"
    echo "  --number       Print line numbers before each line"
    echo "  --skip-empty   Skip empty lines"
    echo ""
    echo "If FILE is not given, defaults to ./data.txt"
}

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --number)
            number_lines=true
            shift
            ;;
        --skip-empty)
            skip_empty=true
            shift
            ;;
        -*)
            echo "Error: Unknown option '$1'" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [[ -z "$file_set" ]]; then
                file="$1"
                file_set=true
            else
                echo "Error: Unexpected argument '$1'" >&2
                usage >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# --- Check file exists ---
if [ ! -f "$file" ]; then
    echo "Error: File '$file' not found!" >&2
    exit 1
fi

# --- Read file ---
total_lines=0
output_lines=0
skipped_lines=0

while IFS= read -r line || [[ -n "$line" ]]; do
    total_lines=$((total_lines + 1))

    # Skip empty lines if requested
    if $skip_empty && [[ -z "$line" ]]; then
        skipped_lines=$((skipped_lines + 1))
        continue
    fi

    output_lines=$((output_lines + 1))

    if $number_lines; then
        echo "$output_lines: $line"
    else
        echo "$line"
    fi
done < "$file"

# --- Summary ---
echo ""
echo "--- Summary ---"
echo "Total lines:    $total_lines"
echo "Output lines:   $output_lines"
echo "Skipped (empty): $skipped_lines"
