#!/bin/bash

# Script to reorganize results directory structure
# From: results/<test-type>/<metric>/algorithm_hardware-type_file.bin.csv
# To:   results/<test-type>/<hardware-type>/<test-name>/<algorithm>/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"

echo "Reorganizing results directory structure..."

# Function to process a directory of CSV files
process_directory() {
    local source_dir="$1"
    local test_type="$2"
    local metric="$3"
    
    echo "Processing $source_dir..."
    
    # Find all CSV files in the directory
    for csv_file in "$source_dir"/*.csv; do
        if [[ ! -f "$csv_file" ]]; then
            continue
        fi
        
        local filename=$(basename "$csv_file")
        local name_without_ext="${filename%.csv}"
        
        # Parse filename: algorithm_hardware-type_file.bin
        # Split by underscore, but handle the case where hardware-type might contain hyphens
        local parts=($(echo "$name_without_ext" | tr '_' '\n'))
        
        if [[ ${#parts[@]} -lt 3 ]]; then
            echo "Warning: Skipping file with invalid format: $filename"
            continue
        fi
        
        local algorithm="${parts[0]}"
        local hardware_type="${parts[1]}"
        
        # Reconstruct the file part (everything after hardware-type)
        local file_part=""
        for ((i=2; i<${#parts[@]}; i++)); do
            if [[ -z "$file_part" ]]; then
                file_part="${parts[i]}"
            else
                file_part="${file_part}_${parts[i]}"
            fi
        done
        
        # Create the new directory structure
        local new_dir="$RESULTS_DIR/$test_type/$hardware_type/$file_part/$algorithm"
        mkdir -p "$new_dir"
        
        # Move the file to the new location
        local new_file="$new_dir/$metric.csv"
        mv "$csv_file" "$new_file"
        
        echo "  Moved: $filename -> $new_file"
    done
}

# Process CPU data
if [[ -d "$RESULTS_DIR/sort/cpu" ]]; then
    process_directory "$RESULTS_DIR/sort/cpu" "sort" "cpu"
fi

# Process Memory data
if [[ -d "$RESULTS_DIR/sort/memory" ]]; then
    process_directory "$RESULTS_DIR/sort/memory" "sort" "memory"
fi

# Clean up empty directories
echo "Cleaning up empty directories..."
find "$RESULTS_DIR" -type d -empty -delete

echo "✅ Results reorganization complete!"
echo "New structure: results/<test-type>/<hardware-type>/<test-name>/<algorithm>/<metric>.csv" 