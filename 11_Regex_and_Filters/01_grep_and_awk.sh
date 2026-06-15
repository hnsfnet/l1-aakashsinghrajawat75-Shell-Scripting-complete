#!/bin/bash
# 01_grep_and_awk.sh
#
# A tiny command-line text filter that shows off the classic
# "grep + awk" toolbox in a practical, reusable way.
#
# It reads text from a FILE, from STDIN (a pipe), or from a small
# built-in --demo dataset, and can:
#   * keep only the lines that contain a keyword   (--contains)
#   * do that match case-insensitively             (--ignore-case)
#   * pull out a single column of comma-separated text (--column N)
#   * report how many result lines there are       (--count)
#
# The options compose in a natural order:
#     input  ->  --contains  ->  --column  ->  --count
#
# No external dependencies beyond grep/awk/cat, which ship with bash.

prog="$(basename "$0")"

# --- option state (empty string means "not set") ---------------------------
file=""
file_set=""
pattern=""
contains_set=""
ignore_case=""
column=""
column_set=""
count_set=""
demo_set=""

usage() {
  cat <<EOF
Usage: $prog [OPTIONS] [FILE]

Filter and slice lines of text using grep and awk.

Input:
  FILE                 Read from FILE. If omitted, read from STDIN when data
                       is piped in. Use --demo to run on built-in sample data.

Options:
  --contains PATTERN   Keep only lines that contain PATTERN (literal text).
  --ignore-case        Make --contains match regardless of letter case.
  --column N           Treat input as comma-separated and print column N
                       (1-based). Rows with fewer than N columns are skipped.
  --count              Print the number of result lines instead of the lines.
  --demo               Use a small built-in CSV instead of FILE/STDIN.
  -h, --help           Show this help and exit.

Examples:
  $prog --contains apple fruits.txt
  cat users.csv | $prog --column 1
  $prog --demo --contains apple --ignore-case --column 1
  $prog --demo --contains a --count
EOF
}

die() {
  printf '%s: error: %s\n' "$prog" "$*" >&2
  printf "Run '%s --help' for usage.\n" "$prog" >&2
  exit 1
}

# --- argument parsing -------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --contains)
      [[ $# -ge 2 ]] || die "--contains requires a PATTERN argument"
      pattern="$2"; contains_set=1; shift 2 ;;
    --column)
      [[ $# -ge 2 ]] || die "--column requires a number argument"
      column="$2"; column_set=1; shift 2 ;;
    --ignore-case)
      ignore_case=1; shift ;;
    --count)
      count_set=1; shift ;;
    --demo)
      demo_set=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    --)
      shift; break ;;
    -*)
      die "unknown option: $1" ;;
    *)
      [[ -z "$file_set" ]] || die "only one input file is supported"
      file="$1"; file_set=1; shift ;;
  esac
done

# Any positional arguments left after a literal "--" are treated as the file.
while [[ $# -gt 0 ]]; do
  [[ -z "$file_set" ]] || die "only one input file is supported"
  file="$1"; file_set=1; shift
done

# --- validation -------------------------------------------------------------
if [[ -n "$column_set" ]]; then
  # A column must be a positive integer (1, 2, 3, ... with no leading zero).
  [[ "$column" =~ ^[1-9][0-9]*$ ]] || die "illegal column number: '$column'"
fi

if [[ -n "$file_set" ]]; then
  [[ -e "$file" ]] || die "no such file: '$file'"
  [[ -r "$file" ]] || die "file is not readable: '$file'"
fi

# We need *some* source of input: a file, a pipe on stdin, or --demo.
if [[ -z "$demo_set" && -z "$file_set" && -t 0 ]]; then
  die "no input: pass a FILE, pipe data via stdin, or use --demo"
fi

# --- pipeline stages --------------------------------------------------------
# Each stage reads stdin and writes stdout. When its option is not set the
# stage is a transparent passthrough (plain "cat"), so the four stages can be
# chained unconditionally below.

emit_input() {
  if [[ -n "$demo_set" ]]; then
    printf '%s\n' \
      "name,fruit,price" \
      "Aakash,apple,12" \
      "Rahul,banana,7" \
      "Meera,cherry,20" \
      "Sofia,Apple,15"
  elif [[ -n "$file_set" ]]; then
    cat -- "$file"
  else
    cat
  fi
}

filter_contains() {
  if [[ -n "$contains_set" ]]; then
    # -F: match PATTERN literally (no regex surprises for a "contains" filter).
    # -e: make sure a PATTERN starting with '-' is not read as an option.
    # No match is a normal outcome here, so swallow grep's non-zero exit.
    if [[ -n "$ignore_case" ]]; then
      grep -F -i -e "$pattern" || true
    else
      grep -F -e "$pattern" || true
    fi
  else
    cat
  fi
}

extract_column() {
  if [[ -n "$column_set" ]]; then
    awk -F',' -v c="$column" 'NF >= c { print $c }'
  else
    cat
  fi
}

maybe_count() {
  if [[ -n "$count_set" ]]; then
    # NR counts records robustly, even when the last line lacks a newline.
    awk 'END { print NR }'
  else
    cat
  fi
}

# input -> contains -> column -> count
emit_input | filter_contains | extract_column | maybe_count
