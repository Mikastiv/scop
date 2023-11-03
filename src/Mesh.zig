const std = @import("std");
const Self = @This();
const Vertex = @import("Vertex.zig");
const Material = @import("Material.zig");
const math = @import("math.zig");
const Vec3 = math.Vec3;
const Vec2 = math.Vec2;
const c = @import("c.zig");

allocator: std.mem.Allocator,
name: []const u8,
vao: c.GLuint,
vbo: c.GLuint,
ebo: c.GLuint,
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
        .vao = 0,
        .vbo = 0,
        .ebo = 0,
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

    c.glGenBuffers(1, @ptrCast(&self.vbo));
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @sizeOf(Vertex) * @as(c.GLsizeiptr, @intCast(self.vertices.items.len)),
        self.vertices.items.ptr,
        c.GL_STATIC_DRAW,
    );

    c.glGenBuffers(1, @ptrCast(&self.ebo));
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, self.ebo);
    c.glBufferData(
        c.GL_ELEMENT_ARRAY_BUFFER,
        @sizeOf(u16) * @as(c.GLsizeiptr, @intCast(self.indices.items.len)),
        self.indices.items.ptr,
        c.GL_STATIC_DRAW,
    );

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

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);
}
