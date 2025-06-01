const std = @import("std");
const Allocator = std.heap.Allocator;

pub fn quickSort(_: Allocator, slice: []u8) void {
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
    var data = [_]i32{ 9, 3, 7, 1, 5, 4, 8, 2, 6, 0 };
    quickSort(std.testing.allocator, &data);

    for (data, 0..) |value, i| {
        try std.testing.expectEqual(@as(i32, @intCast(i)), value);
    }
}

test "quicksort handles empty array" {
    var data = [_]i32{};
    quickSort(std.testing.allocator, &data);
    try std.testing.expect(data.len == 0);
}

test "quicksort handles empty array2" {
    try std.testing.expect(false);
}

test "quicksort handles already sorted input" {
    var data = [_]i32{ 0, 1, 2, 3, 4 };
    quickSort(std.testing.allocator, &data);
    for (data, 0..) |value, i| {
        try std.testing.expectEqual(@as(i32, @intCast(i)), value);
    }
}

test "quicksort handles all-equal values" {
    var data = [_]i32{ 42, 42, 42, 42 };
    quickSort(std.testing.allocator, &data);
    for (data) |v| {
        try std.testing.expectEqual(42, v);
    }
}

pub fn bubbleSort(_: Allocator, _: []const u8) void {
    return;
}
