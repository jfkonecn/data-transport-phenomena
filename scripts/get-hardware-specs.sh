#!/bin/bash

# Check if run name argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Run name argument is required"
    echo "Usage: $0 <run_name>"
    exit 1
fi

RUN_NAME="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"/..

# Create results directory if it doesn't exist
mkdir -p "./results/hardware-specs"

# Redirect all output to the file
{
    echo -e "=== PRE-RUN CPU FREQUENCY ==="
    cat /proc/cpuinfo | grep MHz

    echo -e "\n=== CPU INFORMATION ==="
    lscpu

    echo -e "\n=== MEMORY INFORMATION ==="
    sudo lshw -class memory -sanitize

    taskset -c 0 zig build run -- bubble-sort ./data/sort/12_50K.bin cpu test --out-dir /dev/null > /dev/null 2>&1

    echo -e "\n=== POST-RUN CPU FREQUENCY ==="
    cat /proc/cpuinfo | grep MHz
} > "./results/hardware-specs/$RUN_NAME.txt" 2>&1

echo "Hardware specifications saved to ./results/hardware-specs/$RUN_NAME.txt"