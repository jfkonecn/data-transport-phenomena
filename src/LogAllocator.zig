const std = @import("std");
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;

pub const LogAllocator = struct {
    base_allocator: Allocator,
    log_buffer: std.ArrayList(u8),

    pub fn init(base_allocator: Allocator) LogAllocator {
        return LogAllocator{
            .base_allocator = base_allocator,
            .log_buffer = std.ArrayList(u8).init(base_allocator),
        };
    }

    pub fn deinit(self: *LogAllocator) void {
        self.log_buffer.deinit();
    }

    pub fn allocator(self: *LogAllocator) Allocator {
        return Allocator{
            .ptr = self,
            .vtable = &Self.vtable,
        };
    }

    pub fn printLog(self: *LogAllocator) !void {
        const stdout = std.io.getStdOut().writer();
        try stdout.writeAll(self.log_buffer.items);
    }

    const Self = @This();

    const vtable = Allocator.VTable{
        .alloc = alloc,
        .resize = resize,
        .remap = remap,
        .free = free,
    };

    fn writeLog(self: *Self, comptime fmt: []const u8, args: anytype) void {
        self.log_buffer.writer().print(fmt, args) catch {};
    }

    fn alloc(ctx: *anyopaque, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8 {
        const self: *Self = @alignCast(@ptrCast(ctx));
        const result = self.base_allocator.rawAlloc(len, alignment, ret_addr);
        self.writeLog("ALLOC {d} bytes align {d} => {any}\n", .{ len, alignment, result });
        return result;
    }

    fn resize(ctx: *anyopaque, mem: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool {
        const self: *Self = @alignCast(@ptrCast(ctx));
        const result = self.base_allocator.rawResize(mem, alignment, new_len, ret_addr);
        self.writeLog("RESIZE {any} to {d} bytes => {any}\n", .{ mem.ptr, new_len, result });
        return result;
    }

    fn remap(ctx: *anyopaque, mem: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        const self: *Self = @alignCast(@ptrCast(ctx));
        const result = self.base_allocator.rawRemap(mem, alignment, new_len, ret_addr);
        self.writeLog("REMAP {any} to {d} bytes => {any}\n", .{ mem.ptr, new_len, result });
        return result;
    }

    fn free(ctx: *anyopaque, mem: []u8, alignment: Alignment, ret_addr: usize) void {
        const self: *Self = @alignCast(@ptrCast(ctx));
        self.writeLog("FREE {any} align {d}\n", .{ mem.ptr, alignment });
        self.base_allocator.rawFree(mem, alignment, ret_addr);
    }
};
