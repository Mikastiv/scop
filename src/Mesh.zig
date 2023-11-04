const std = @import("std");
const Self = @This();
const Vertex = @import("Vertex.zig");
const Material = @import("Material.zig");
const math = @import("math.zig");
const Vec3 = math.Vec3;
const Vec2 = math.Vec2;
const VertexBuffer = @import("VertexBuffer.zig");
const IndexBuffer = @import("IndexBuffer.zig");
const c = @import("c.zig");

allocator: std.mem.Allocator,
name: []const u8,
vao: c.GLuint = c.GL_INVALID_VALUE,
vertex_buffer: VertexBuffer,
index_buffer: IndexBuffer,
vertices: std.ArrayList(Vertex),
indices: std.ArrayList(u16),
material: *const Material,

const default_material = Material{
    .name = "default",
};

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .allocator = allocator,
        .name = "",
        .vao = c.GL_INVALID_VALUE,
        .vertex_buffer = .{ .id = c.GL_INVALID_VALUE },
        .index_buffer = .{ .id = c.GL_INVALID_VALUE },
        .vertices = std.ArrayList(Vertex).init(allocator),
        .indices = std.ArrayList(u16).init(allocator),
        .material = &default_material,
    };
}

pub fn deinit(self: *Self) void {
    self.vertices.deinit();
    self.indices.deinit();
}

pub fn loadOnGpu(self: *Self) void {
    c.glGenVertexArrays(1, @ptrCast(&self.vao));
    c.glBindVertexArray(self.vao);

    self.vertex_buffer = VertexBuffer.init(Vertex, self.vertices.items);
    self.index_buffer = IndexBuffer.init(u16, self.indices.items);

    c.glEnableVertexAttribArray(0);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "pos")));
    c.glEnableVertexAttribArray(1);
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "normal")));
    c.glEnableVertexAttribArray(2);
    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "uv")));
    c.glEnableVertexAttribArray(3);
    c.glVertexAttribPointer(3, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "tangent")));
    c.glEnableVertexAttribArray(4);
    c.glVertexAttribPointer(4, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "bitangent")));

    c.glBindVertexArray(0);
}

pub fn draw(self: *const Self) void {
    c.glBindVertexArray(self.vao);
    c.glDrawElements(c.GL_TRIANGLES, @intCast(self.indices.items.len), c.GL_UNSIGNED_SHORT, null);
    c.glBindVertexArray(0);
}
