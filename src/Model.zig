const std = @import("std");
const Self = @This();
const Mesh = @import("Mesh.zig");
const Material = @import("Material.zig");

allocator: std.mem.Allocator,
meshes: std.ArrayList(Mesh),
materials: std.ArrayList(Material),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .allocator = allocator,
        .meshes = std.ArrayList(Mesh).init(allocator),
        .materials = std.ArrayList(Material).init(allocator),
    };
}
