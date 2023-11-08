const std = @import("std");
const Self = @This();
const Vec3 = @import("math.zig").Vec3;
const Texture = @import("Texture.zig");
const Image = @import("Image.zig");

pub const default = init("default");

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

fn loadColorSourceOnGpu(source: *ColorSource, allocator: std.mem.Allocator) !void {
    switch (source.*) {
        .rgb => |color| {
            const pixels = try allocator.alloc(u32, 1);
            const r: u32 = @intFromFloat(color[0] * std.math.maxInt(u8));
            const g: u32 = @intFromFloat(color[1] * std.math.maxInt(u8));
            const b: u32 = @intFromFloat(color[2] * std.math.maxInt(u8));
            const a = 0xFF;
            pixels[0] = a << 24 | b << 16 | g << 8 | r;
            const image = Image{ .allocator = allocator, .bpp = 32, .width = 1, .height = 1, .pixels = pixels };
            source.* = .{ .texture = .{ .image = image } };
            source.texture.loadOnGpu();
        },
        .texture => |*tex| tex.loadOnGpu(),
    }
}

pub fn loadOnGpu(self: *Self, allocator: std.mem.Allocator) !void {
    try loadColorSourceOnGpu(&self.ambient, allocator);
    try loadColorSourceOnGpu(&self.albedo, allocator);
    try loadColorSourceOnGpu(&self.specular, allocator);
    try loadColorSourceOnGpu(&self.roughness, allocator);
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
