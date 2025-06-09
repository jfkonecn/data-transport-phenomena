#!/bin/bash

# Ensure a name is passed
if [ $# -lt 1 ]; then
    echo "Usage: $0 <name-for-output> [optional-algorithms...]"
    exit 1
fi

# Name for output CSV (required)
RUN_NAME="$1"
shift

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Allow overriding algorithms as optional trailing args
if [ "$#" -gt 0 ]; then
    ALGORITHMS=("$@")
else
    ALGORITHMS=("quick-sort" "merge-sort" "bubble-sort")
fi

# Input files (relative to script)
INPUT_DIR="$SCRIPT_DIR/../data/sort"
INPUT_FILES=("$INPUT_DIR"/*)

OUT_FILE="$SCRIPT_DIR/../results/sort/benchmark_${RUN_NAME}.csv"
echo "run_number,cycles,allocated_bytes,cpu_clock_hz,algorithm,file,file_size_bytes" > "$OUT_FILE"

# Run all benchmarks
for ALGORITHM in "${ALGORITHMS[@]}"; do
    for INPUT_PATH in "${INPUT_FILES[@]}"; do
        FILE_NAME="$(basename "$INPUT_PATH")"
        FILE_SIZE=$(stat -c %s "$INPUT_PATH")

        echo "Running $ALGORITHM on $FILE_NAME..."
        OUTPUT=$(taskset -c 0 zig build run -- "$ALGORITHM" "$INPUT_PATH")

        # Get CPU clock speed
        CPU_CLOCK=$(echo "$OUTPUT" | grep "Estimated CPU clock speed" | sed -E 's/.*: ([0-9]+) Hz.*/\1/')

        # Extract per-run data
        RUN_NUM=0
        ALLOC_TOTAL=0

        while IFS= read -r line; do
            if [[ "$line" =~ ^Run\ ([0-9]+):\ ([0-9]+)\ cycles ]]; then
                RUN_NUM="${BASH_REMATCH[1]}"
                CYCLES="${BASH_REMATCH[2]}"
                ALLOC_TOTAL=0
            elif [[ "$line" =~ ^ALLOC\ ([0-9]+)\ bytes ]]; then
                BYTES="${BASH_REMATCH[1]}"
                ((ALLOC_TOTAL+=BYTES))
            elif [[ "$line" =~ ^FREE ]]; then
                echo "$RUN_NUM,$CYCLES,$ALLOC_TOTAL,$CPU_CLOCK,$ALGORITHM,$FILE_NAME,$FILE_SIZE" >> "$OUT_FILE"
            fi
        done <<< "$OUTPUT"
    done
done

echo "✅ All benchmarks complete. Results saved to $OUT_FILE"
