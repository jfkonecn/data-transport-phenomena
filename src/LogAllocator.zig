const std = @import("std");
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;

const stdout = std.io.getStdOut().writer();
pub const LogAllocator = struct {
    base_allocator: Allocator,

    pub fn init(base_allocator: Allocator) LogAllocator {
        return LogAllocator{
            .base_allocator = base_allocator,
        };
    }

    pub fn allocator(self: *LogAllocator) Allocator {
        return Allocator{
            .ptr = self,
            .vtable = &Self.vtable,
        };
    }

    const Self = @This();

    const vtable = Allocator.VTable{
        .alloc = alloc,
        .resize = resize,
        .remap = remap,
        .free = free,
    };

    fn alloc(ctx: *anyopaque, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8 {
        const self: *Self = @alignCast(@ptrCast(ctx));
        const result = self.base_allocator.rawAlloc(len, alignment, ret_addr);
        stdout.print("ALLOC {d} bytes align {d} => {any}\n", .{ len, alignment, result }) catch {};
        return result;
    }

    fn resize(ctx: *anyopaque, mem: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool {
        const self: *Self = @alignCast(@ptrCast(ctx));
        const result = self.base_allocator.rawResize(mem, alignment, new_len, ret_addr);
        stdout.print("RESIZE {any} to {d} bytes => {any}\n", .{ mem.ptr, new_len, result }) catch {};
        return result;
    }

    fn remap(ctx: *anyopaque, mem: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        const self: *Self = @alignCast(@ptrCast(ctx));
        const result = self.base_allocator.rawRemap(mem, alignment, new_len, ret_addr);
        stdout.print("REMAP {any} to {d} bytes => {any}\n", .{ mem.ptr, new_len, result }) catch {};
        return result;
    }

    fn free(ctx: *anyopaque, mem: []u8, alignment: Alignment, ret_addr: usize) void {
        const self: *Self = @alignCast(@ptrCast(ctx));
        stdout.print("FREE {any} align {d}\n", .{ mem.ptr, alignment }) catch {};
        self.base_allocator.rawFree(mem, alignment, ret_addr);
    }
};
