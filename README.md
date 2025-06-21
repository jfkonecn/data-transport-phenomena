# Data Transport Phenomena

This project contains benchmarking data for sorting algorithms with CPU and memory measurements.

## Project Structure

- `data/sort/` - Input data files of various sizes (100 bytes to 100K bytes)
- `results/sort/cpu/` - CPU performance measurements for different sorting algorithms
- `results/sort/memory/` - Memory allocation/deallocation data for different sorting algorithms
- `aggregate_data.go` - Go program to generate Excel reports from the benchmark data
- `scripts/` - Bash scripts for running benchmarks and data aggregation

## Prerequisites

### Installing Zig

Zig is required for building and running the benchmarks. Please visit the [official Zig website](https://ziglang.org/download/) for installation instructions for your platform.

For ARM devices, you can also use the project's ARM setup:

```bash
cd arm-setup
./install.sh
```

### Installing Go

- Go 1.21 or later
- Git (for dependency management)

Install Go from [golang.org](https://golang.org/dl/) or use your system's package manager.

## Building and Running

### Running the Benchmarks

1. **Run the sorting benchmarks**:

   ```bash
   ./scripts/sort-benchmark.sh <run-name>
   ```

   Replace `<run-name>` with a name for your test run (e.g., "i9", "my-run", "performance-run"). This name will appear in the output CSV files and Excel reports.

### Generating Excel Reports

1. **Install Go dependencies** (first time only):

   ```bash
   go mod tidy
   ```

2. **Generate the Excel file**:

   ```bash
   ./scripts/aggregate-data.sh
   ```

   This will create `aggregate_data.xlsx` in the current directory.

## Data Generation Commands

For reference, here are commands to generate test data files:

```sh
# Gigabytes
head -c 1G </dev/urandom >myfile
# Megabytes
head -c 1M </dev/urandom >myfile
# Kilobytes
head -c 1K </dev/urandom >myfile
# Bytes
head -c 1 </dev/urandom >myfile
```
