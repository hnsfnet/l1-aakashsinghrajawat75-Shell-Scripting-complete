#!/bin/bash
# Reading a text file line by line (a small, reusable viewer)
#
# Usage:
#   bash 02_reading_a_file.sh [FILE] [--number] [--skip-empty]
#
# If no FILE is given, it defaults to data.txt in the current directory.

# --- defaults ---
file=""          # filled from the first positional argument; falls back to data.txt
number=0         # 1 => print a line number in front of every line
skip_empty=0     # 1 => do not print empty lines

usage() {
    # Print how to use the script. Goes to stderr so it never mixes with the file output.
    echo "Usage: bash 02_reading_a_file.sh [FILE] [--number] [--skip-empty]" >&2
    echo "  FILE          path to the text file to read (default: data.txt)" >&2
    echo "  --number      show a line number in front of every line" >&2
    echo "  --skip-empty  do not print empty lines" >&2
}

# --- parse the arguments (flags and the file path may appear in any order) ---
while [ "$#" -gt 0 ]; do
    case "$1" in
        --number)
            number=1
            ;;
        --skip-empty)
            skip_empty=1
            ;;
        --*)
            echo "Error: unknown option '$1'" >&2
            usage
            exit 2
            ;;
        *)
            if [ -z "$file" ]; then
                file="$1"
            else
                echo "Error: too many file arguments ('$1')" >&2
                usage
                exit 2
            fi
            ;;
    esac
    shift
done

# Fall back to the default file name when no path was provided.
if [ -z "$file" ]; then
    file="data.txt"
fi

# --- make sure the file actually exists before we try to read it ---
if [ ! -f "$file" ]; then
    echo "Error: file '$file' not found!" >&2
    exit 1
fi

# --- read the file line by line ---
total=0      # every line we read from the file
printed=0    # lines we actually sent to the screen
skipped=0    # empty lines we skipped because of --skip-empty

# "IFS= read -r" keeps each line exactly as it is (no trimming, no backslash escapes).
# The '|| [ -n "$line" ]' part makes sure we still handle a final line that has no
# trailing newline.
while IFS= read -r line || [ -n "$line" ]; do
    total=$((total + 1))

    # Skip empty lines when the user asked us to.
    if [ "$skip_empty" -eq 1 ] && [ -z "$line" ]; then
        skipped=$((skipped + 1))
        continue
    fi

    if [ "$number" -eq 1 ]; then
        printf '%6d  %s\n' "$total" "$line"
    else
        echo "$line"
    fi

    printed=$((printed + 1))
done < "$file"

# --- summary ---
echo "----------------------------------------"
echo "Summary for '$file':"
echo "  Total lines:   $total"
echo "  Printed lines: $printed"
echo "  Skipped empty: $skipped"
