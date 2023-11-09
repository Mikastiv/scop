const std = @import("std");
const Self = @This();
const Mesh = @import("Mesh.zig");
const Material = @import("Material.zig");
const Shader = @import("Shader.zig");

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

pub fn deinit(self: *const Self) void {
    for (self.meshes.items) |*mesh| {
        mesh.deinit();
    }
    self.meshes.deinit();
    for (self.materials.items) |material| {
        material.deinit(self.allocator);
    }
    self.materials.deinit();
}

pub fn loadOnGpu(self: *Self) !void {
    for (self.meshes.items) |*mesh| {
        mesh.loadOnGpu();
    }
    for (self.materials.items) |*material| {
        try material.loadOnGpu(self.allocator);
    }
}

pub fn draw(self: *const Self, shader: Shader) void {
    for (self.meshes.items) |mesh| {
        mesh.draw(shader);
    }
}
