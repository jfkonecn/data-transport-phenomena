const std = @import("std");
const sort = @import("sort.zig");
const LogAllocator = @import("LogAllocator.zig").LogAllocator;

extern fn readCpuTimer() callconv(.C) u64;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const AlgorithmFn = fn (std.mem.Allocator, []u8) void;

fn print_clock_speed() !void {
    const sleep_time = 1_000_000_000; // 1 second in nanoseconds

    const start_cycles = readCpuTimer();
    std.time.sleep(sleep_time); // sleep 1 second
    const end_cycles = readCpuTimer();

    const delta_cycles = end_cycles - start_cycles;

    try stdout.print("Estimated CPU clock speed: {} Hz ({} MHz)\n", .{
        delta_cycles,
        delta_cycles / 1_000_000,
    });
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const available_algorithms = [_][]const u8{
        "quick-sort",
        "bubble-sort",
        "merge-sort",
    };

    if (args.len < 2 or std.mem.eql(u8, args[1], "--help")) {
        try stdout.print(
            \\Usage:
            \\  {s} <algorithm-name> <binary-file>
            \\
            \\Options:
            \\  --help            Show this help message
            \\
            \\Available algorithms:
        , .{args[0]});

        for (available_algorithms) |alg| {
            try stdout.print("\\  - {s}\n", .{alg});
        }

        try stdout.print(
            \\
            \\Examples:
            \\  {s} quick-sort input.bin
            \\
        , .{args[0]});

        return;
    }

    if (args.len < 3) {
        try stderr.print("Error: missing binary-file input.\nUse --help for usage.\n", .{});
        return error.NoBinaryFileInput;
    }

    const file_path = args[2];

    const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    const original_data = try allocator.alloc(u8, file_size);
    defer allocator.free(original_data);

    _ = try file.readAll(original_data);

    try print_clock_speed();

    const num_runs = 10;

    const algorithm_name = args[1];
    for (0..num_runs) |run_index| {
        var log_alloc_builder = LogAllocator.init(allocator);
        defer log_alloc_builder.deinit();
        const data = try allocator.dupe(u8, original_data);
        defer allocator.free(data);
        const log_alloc = log_alloc_builder.allocator();
        const start = readCpuTimer();
        if (std.mem.eql(u8, algorithm_name, "quick-sort")) {
            sort.quickSort(data);
        } else if (std.mem.eql(u8, algorithm_name, "bubble-sort")) {
            sort.bubbleSort(data);
        } else if (std.mem.eql(u8, algorithm_name, "merge-sort")) {
            try sort.mergeSort(log_alloc, data);
        } else {
            try stderr.print("Unknown algorithm: {s}\nUse --help to see available options.\n", .{algorithm_name});
            std.process.exit(1);
        }
        const cycles = readCpuTimer() - start;
        try stdout.print("Run {d}: {d} cycles\n", .{ run_index + 1, cycles });
        try log_alloc_builder.printLog();
    }
}
