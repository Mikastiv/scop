const std = @import("std");
const Self = @This();
const Vec3 = @import("math.zig").Vec3;

name: []const u8 = "",
ambient: Vec3 = .{ 0, 0, 0 },
diffuse: Vec3 = .{ 0, 0, 0 },
specular: Vec3 = .{ 0, 0, 0 },
