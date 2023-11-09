const std = @import("std");
const Self = @This();
const Vec3 = @import("math.zig").Vec3;
const Texture = @import("Texture.zig");
const Image = @import("Image.zig");

pub const default = init("default");

name: []const u8,
ambient: Vec3 = .{ 0, 0, 0 },
ambient_map: ?Texture = null,
albedo: Vec3 = .{ 0, 0, 0 },
albedo_map: ?Texture = null,
specular: Vec3 = .{ 0, 0, 0 },
specular_map: ?Texture = null,
roughness: Vec3 = .{ 0, 0, 0 },
roughness_map: ?Texture = null,
normal_map: ?Texture = null,

pub fn init(name: []const u8) Self {
    return .{
        .name = name,
    };
}

fn createTextureForColor(color: Vec3, allocator: std.mem.Allocator) !Texture {
    const pixels = try allocator.alloc(u32, 1);
    const r: u32 = @intFromFloat(color[0] * std.math.maxInt(u8));
    const g: u32 = @intFromFloat(color[1] * std.math.maxInt(u8));
    const b: u32 = @intFromFloat(color[2] * std.math.maxInt(u8));
    const a = 0xFF;
    pixels[0] = a << 24 | b << 16 | g << 8 | r;
    const image = Image{ .allocator = allocator, .bpp = 32, .width = 1, .height = 1, .pixels = pixels };
    return .{ .image = image };
}

pub fn loadOnGpu(self: *Self, allocator: std.mem.Allocator) !void {
    if (self.ambient_map == null) {
        self.ambient_map = try createTextureForColor(self.ambient, allocator);
    }
    self.ambient_map.?.loadOnGpu();
    if (self.albedo_map == null) {
        self.albedo_map = try createTextureForColor(self.albedo, allocator);
    }
    self.albedo_map.?.loadOnGpu();
    if (self.specular_map == null) {
        self.specular_map = try createTextureForColor(self.specular, allocator);
    }
    self.specular_map.?.loadOnGpu();
    if (self.roughness_map == null) {
        self.roughness_map = try createTextureForColor(self.roughness, allocator);
    }
    self.roughness_map.?.loadOnGpu();
}

pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
    if (self.ambient_map) |m| allocator.free(m.image.pixels);
    if (self.albedo_map) |m| allocator.free(m.image.pixels);
    if (self.specular_map) |m| allocator.free(m.image.pixels);
    if (self.roughness_map) |m| allocator.free(m.image.pixels);
    if (self.normal_map) |m| allocator.free(m.image.pixels);
}
