const Self = @This();
const std = @import("std");

allocator: std.mem.Allocator,
pixels: []u32,
width: u64,
height: u64,
bpp: u16,

pub fn deinit(self: *const Self) void {
    self.allocator.free(self.pixels);
}
