#!/bin/bash

# Ensure a name is passed
if [ $# -lt 1 ]; then
    echo "Usage: $0 <name-for-output> [optional-algorithms...]"
    exit 1
fi

RUN_NAME="$1"
shift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -gt 0 ]; then
    ALGORITHMS=("$@")
else
    ALGORITHMS=("quick-sort" "merge-sort" "bubble-sort")
fi

INPUT_DIR="$SCRIPT_DIR/../data/sort"
INPUT_FILES=("$INPUT_DIR"/*)

OUT_DIR="$SCRIPT_DIR/../results/sort"

for ALGORITHM in "${ALGORITHMS[@]}"; do
    for INPUT_PATH in "${INPUT_FILES[@]}"; do
        FILE_NAME="$(basename "$INPUT_PATH")"
        FILE_SIZE=$(stat -c %s "$INPUT_PATH")

        echo "Running $ALGORITHM on $FILE_NAME..."

        echo "CPU Test..."
        taskset -c 0 zig build run -- "$ALGORITHM" "$INPUT_PATH" cpu "$RUN_NAME" --out-dir "$OUT_DIR"

        echo "Memory Test..."
        taskset -c 0 zig build run -- "$ALGORITHM" "$INPUT_PATH" memory "$RUN_NAME" --out-dir "$OUT_DIR"
    done
done

echo "✅ All benchmarks complete. Results saved to $OUT_DIR"
