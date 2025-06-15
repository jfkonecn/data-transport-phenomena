const std = @import("std");
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;

pub fn LogAllocator(comptime WriterType: type) type {
    return struct {
        base_allocator: Allocator,
        writer: WriterType,
        algorithm_name: [:0]u8,
        file_name: []const u8,
        file_size: u64,

        const Self = @This();

        pub fn init(
            // force zig fmt wrap
            base_allocator: Allocator,
            writer: WriterType,
            algorithm_name: [:0]u8,
            file_name: []const u8,
            file_size: u64,
        ) !Self {
            try writer.print("alignment,allocation_type,allocation_size_bytes,algorithm,file,file_size_bytes", .{});
            return .{
                .base_allocator = base_allocator,
                .writer = writer,
                .algorithm_name = algorithm_name,
                .file_name = file_name,
                .file_size = file_size,
            };
        }

        pub fn allocator(self: *Self) Allocator {
            return Allocator{
                .ptr = self,
                .vtable = &Self.vtable,
            };
        }

        const vtable = Allocator.VTable{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        };

        fn writeLog(self: *Self, alignment: Alignment, comptime allocation_type: []const u8, len: usize) void {
            _ = self.writer.print("\n{d},{s},{d},{s},{s},{d}", .{
                alignment,
                allocation_type,
                len,
                self.algorithm_name,
                self.file_name,
                self.file_size,
            }) catch {};
        }

        fn alloc(ctx: *anyopaque, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8 {
            const self: *Self = @alignCast(@ptrCast(ctx));
            const result = self.base_allocator.rawAlloc(len, alignment, ret_addr);
            self.writeLog(alignment, "ALLOC", len);
            return result;
        }

        fn resize(ctx: *anyopaque, mem: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool {
            const self: *Self = @alignCast(@ptrCast(ctx));
            const result = self.base_allocator.rawResize(mem, alignment, new_len, ret_addr);
            self.writeLog(alignment, "RESIZE", new_len);
            return result;
        }

        fn remap(ctx: *anyopaque, mem: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
            const self: *Self = @alignCast(@ptrCast(ctx));
            const result = self.base_allocator.rawRemap(mem, alignment, new_len, ret_addr);
            self.writeLog(alignment, "REMAP", new_len);
            return result;
        }

        fn free(ctx: *anyopaque, mem: []u8, alignment: Alignment, ret_addr: usize) void {
            const self: *Self = @alignCast(@ptrCast(ctx));
            self.writeLog(alignment, "FREE", mem.len);
            self.base_allocator.rawFree(mem, alignment, ret_addr);
        }
    };
}
