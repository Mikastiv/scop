const std = @import("std");
const Self = @This();
const Vertex = @import("Vertex.zig");
const Material = @import("Material.zig");

allocator: std.mem.Allocator,
name: []const u8,
vertices: std.ArrayList(Vertex),
indices: std.ArrayList(u16),
material: ?*const Material,

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .allocator = allocator,
        .name = "",
        .vertices = std.ArrayList(Vertex).init(allocator),
        .indices = std.ArrayList(u16).init(allocator),
        .material = null,
    };
}
