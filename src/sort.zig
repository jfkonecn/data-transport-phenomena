const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn quickSort(slice: []u8) void {
    if (slice.len <= 1) return;

    const pivot = slice[slice.len / 2];
    var left: usize = 0;
    var right: usize = slice.len - 1;

    while (left <= right) {
        while (slice[left] < pivot) left += 1;
        while (slice[right] > pivot) right -= 1;

        if (left <= right) {
            const tmp = slice[left];
            slice[left] = slice[right];
            slice[right] = tmp;
            left += 1;
            if (right == 0) break;
            right -= 1;
        }
    }

    quickSort(slice[0 .. right + 1]);
    quickSort(slice[left..]);
}

test "quicksort sorts integers" {
    var data = [_]u8{ 9, 3, 7, 1, 5, 4, 8, 2, 6, 0 };
    quickSort(&data);

    for (data, 0..) |value, i| {
        try std.testing.expectEqual(@as(u8, @intCast(i)), value);
    }
}

test "quicksort handles empty array" {
    var data = [_]u8{};
    quickSort(&data);
    try std.testing.expect(data.len == 0);
}

test "quicksort handles already sorted input" {
    var data = [_]u8{ 0, 1, 2, 3, 4 };
    quickSort(&data);
    for (data, 0..) |value, i| {
        try std.testing.expectEqual(@as(u8, @intCast(i)), value);
    }
}

test "quicksort handles all-equal values" {
    var data = [_]u8{ 42, 42, 42, 42 };
    quickSort(&data);
    for (data) |v| {
        try std.testing.expectEqual(42, v);
    }
}

pub fn bubbleSort(data: []u8) void {
    const len = data.len;
    for (0..len) |_| {
        var swapped = false;
        for (0..len - 1) |i| {
            if (data[i] > data[i + 1]) {
                const tmp = data[i];
                data[i] = data[i + 1];
                data[i + 1] = tmp;
                swapped = true;
            }
        }
        if (!swapped) break;
    }
}

test "bubbleSort sorts integers" {
    var data = [_]u8{ 9, 3, 7, 1, 5, 4, 8, 2, 6, 0 };
    bubbleSort(&data);

    for (data, 0..) |value, i| {
        try std.testing.expectEqual(@as(u8, @intCast(i)), value);
    }
}

test "bubbleSort handles empty array" {
    var data = [_]u8{};
    bubbleSort(&data);
    try std.testing.expect(data.len == 0);
}

test "bubbleSort handles already sorted input" {
    var data = [_]u8{ 0, 1, 2, 3, 4 };
    bubbleSort(&data);
    for (data, 0..) |value, i| {
        try std.testing.expectEqual(@as(u8, @intCast(i)), value);
    }
}

test "bubbleSort handles all-equal values" {
    var data = [_]u8{ 42, 42, 42, 42 };
    bubbleSort(&data);
    for (data) |v| {
        try std.testing.expectEqual(42, v);
    }
}

pub fn mergeSort(allocator: Allocator, data: []u8) !void {
    if (data.len <= 1) return;

    const mid = data.len / 2;
    const left = data[0..mid];
    const right = data[mid..];

    try mergeSort(allocator, left);
    try mergeSort(allocator, right);

    var temp = try allocator.alloc(u8, data.len);
    defer allocator.free(temp);

    var i: usize = 0;
    var l: usize = 0;
    var r: usize = 0;

    while (l < left.len and r < right.len) : (i += 1) {
        temp[i] = if (left[l] <= right[r]) blk: {
            const val = left[l];
            l += 1;
            break :blk val;
        } else blk: {
            const val = right[r];
            r += 1;
            break :blk val;
        };
    }

    while (l < left.len) : (i += 1) {
        temp[i] = left[l];
        l += 1;
    }

    while (r < right.len) : (i += 1) {
        temp[i] = right[r];
        r += 1;
    }

    std.mem.copyForwards(u8, data, temp);
}

test "mergeSort sorts integers" {
    const allocator = std.testing.allocator;
    var data = [_]u8{ 9, 3, 7, 1, 5, 4, 8, 2, 6, 0 };
    try mergeSort(allocator, &data);

    for (data, 0..) |value, i| {
        try std.testing.expectEqual(@as(u8, @intCast(i)), value);
    }
}

test "mergeSort handles empty array" {
    const allocator = std.testing.allocator;
    var data = [_]u8{};
    try mergeSort(allocator, &data);
    try std.testing.expect(data.len == 0);
}

test "mergeSort handles already sorted input" {
    const allocator = std.testing.allocator;
    var data = [_]u8{ 0, 1, 2, 3, 4 };
    try mergeSort(allocator, &data);
    for (data, 0..) |value, i| {
        try std.testing.expectEqual(@as(u8, @intCast(i)), value);
    }
}

test "mergeSort handles all-equal values" {
    const allocator = std.testing.allocator;
    var data = [_]u8{ 42, 42, 42, 42 };
    try mergeSort(allocator, &data);
    for (data) |v| {
        try std.testing.expectEqual(42, v);
    }
}
