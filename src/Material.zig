const std = @import("std");
const Self = @This();
const Vec3 = @import("math.zig").Vec3;
const Texture = @import("Texture.zig");

pub const ColorSource = union(enum) {
    rgb: Vec3,
    texture: Texture,
};

name: []const u8,
ambient: ColorSource = .{ .rgb = .{ 0, 0, 0 } },
albedo: ColorSource = .{ .rgb = .{ 0, 0, 0 } },
specular: ColorSource = .{ .rgb = .{ 0, 0, 0 } },
roughness: ColorSource = .{ .rgb = .{ 0, 0, 0 } },
normal_map: ?Texture = null,

pub fn init(name: []const u8) Self {
    return .{
        .name = name,
    };
}

fn freeImage(source: ColorSource, allocator: std.mem.Allocator) void {
    switch (source) {
        .texture => |tex| allocator.free(tex.image.pixels),
        else => {},
    }
}

pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
    freeImage(self.ambient, allocator);
    freeImage(self.albedo, allocator);
    freeImage(self.specular, allocator);
    freeImage(self.roughness, allocator);
    if (self.normal_map) |n| allocator.free(n.image.pixels);
}
