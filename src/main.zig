const std = @import("std");
const sort = @import("sort.zig");
const LogAllocator = @import("LogAllocator.zig").LogAllocator;

extern fn readCpuTimer() callconv(.C) u64;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const AlgorithmFn = fn (std.mem.Allocator, []u8) void;

const TestType = enum { cpu, memory };

fn parseTestType(value: []const u8) !TestType {
    if (std.mem.eql(u8, value, "cpu")) return .cpu;
    if (std.mem.eql(u8, value, "memory")) return .memory;
    return error.InvalidTestType;
}

fn getOutDirArg(args: []const [:0]u8) []const u8 {
    var i: usize = 0;
    while (i + 1 < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--out-dir")) {
            return args[i + 1];
        }
    }
    return ".";
}

fn print_clock_speed() !u64 {
    const sleep_time = 1_000_000_000; // 1 second in nanoseconds

    const start_cycles = readCpuTimer();
    std.time.sleep(sleep_time); // sleep 1 second
    const end_cycles = readCpuTimer();

    const delta_cycles = end_cycles - start_cycles;

    try stdout.print("Estimated CPU clock speed: {} Hz ({} MHz)\n", .{
        delta_cycles,
        delta_cycles / 1_000_000,
    });
    return delta_cycles;
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

    if (args.len < 5 or std.mem.eql(u8, args[1], "--help")) {
        try stdout.print(
            \\Usage:
            \\  {s} <algorithm-name> <binary-file> <cpu|memory> <test-name>
            \\
            \\Available algorithms:
        , .{args[0]});
        for (available_algorithms) |alg| {
            try stdout.print("\\  - {s}\n", .{alg});
        }
        return;
    }

    const algorithm_name = args[1];
    const file_path = args[2];
    const test_type = try parseTestType(args[3]);
    const test_name = args[4];

    const extra_args = args[5..];
    const out_dir = getOutDirArg(extra_args);

    const data_file_name = std.fs.path.basename(file_path);
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    const original_data = try allocator.alloc(u8, file_size);
    defer allocator.free(original_data);
    _ = try file.readAll(original_data);

    const log_filename = try std.fmt.allocPrint(allocator, "{s}/{s}_{s}_{s}.csv", .{ out_dir, algorithm_name, test_name, @tagName(test_type) });

    defer allocator.free(log_filename);
    const log_file = try std.fs.cwd().createFile(log_filename, .{ .truncate = true });
    const log_writer = log_file.writer();

    const runs: usize = switch (test_type) {
        .cpu => 10,
        .memory => 1,
    };

    try stdout.print("Running {s} Test...\n", .{algorithm_name});
    var allocator_to_use = allocator;
    var cpu_clock_hz: u64 = 0;

    switch (test_type) {
        .cpu => {
            cpu_clock_hz = try print_clock_speed();
            try log_writer.print("run_number,cycles,cpu_clock_hz,algorithm,file,file_size_bytes", .{});
        },
        .memory => {
            const LogAlloc = LogAllocator(@TypeOf(log_writer));
            const stat = try file.stat();
            var log_allocator = try LogAlloc.init(allocator, log_writer, algorithm_name, data_file_name, stat.size);
            allocator_to_use = log_allocator.allocator();
        },
    }

    for (0..runs) |run_index| {
        const data = try allocator.dupe(u8, original_data);
        defer allocator.free(data);

        try stdout.print("Run {d}\n", .{run_index + 1});

        const start = readCpuTimer();

        if (std.mem.eql(u8, algorithm_name, "quick-sort")) {
            sort.quickSort(data);
        } else if (std.mem.eql(u8, algorithm_name, "bubble-sort")) {
            sort.bubbleSort(data);
        } else if (std.mem.eql(u8, algorithm_name, "merge-sort")) {
            try sort.mergeSort(allocator_to_use, data);
        } else {
            try stderr.print("Unknown algorithm: {s}\nUse --help to see available options.\n", .{algorithm_name});
            std.process.exit(1);
        }

        const cycles = readCpuTimer() - start;

        if (test_type == .cpu) {
            try log_writer.print("\n{d},{d},{d},{s},{s},{d}", .{ run_index + 1, cycles, cpu_clock_hz, algorithm_name, data_file_name, file_size });
        }
    }
}
