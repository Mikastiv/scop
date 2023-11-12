const std = @import("std");
const Self = @This();
const Vertex = @import("Vertex.zig");
const Material = @import("Material.zig");
const math = @import("math.zig");
const GLBuffer = @import("GLBuffer.zig");
const c = @import("c.zig");
const Shader = @import("Shader.zig");

allocator: std.mem.Allocator,
name: []const u8,
vao: c.GLuint,
vertex_buffer: GLBuffer,
index_buffer: GLBuffer,
primitive: c.GLenum,
vertices: std.ArrayList(Vertex),
indices: std.ArrayList(u16),
material: *const Material,
material_name: []const u8,

pub fn init(allocator: std.mem.Allocator, material: *const Material) Self {
    return .{
        .allocator = allocator,
        .name = "",
        .vao = c.GL_INVALID_VALUE,
        .vertex_buffer = GLBuffer.invalid_buffer,
        .index_buffer = GLBuffer.invalid_buffer,
        .primitive = c.GL_TRIANGLES,
        .vertices = std.ArrayList(Vertex).init(allocator),
        .indices = std.ArrayList(u16).init(allocator),
        .material = material,
        .material_name = material.name,
    };
}

pub fn deinit(self: *const Self) void {
    self.vertices.deinit();
    self.indices.deinit();
}

pub fn loadOnGpu(self: *Self) void {
    c.glGenVertexArrays(1, @ptrCast(&self.vao));
    c.glBindVertexArray(self.vao);

    self.vertex_buffer = GLBuffer.init(Vertex, c.GL_ARRAY_BUFFER, self.vertices.items);
    self.index_buffer = GLBuffer.init(u16, c.GL_ELEMENT_ARRAY_BUFFER, self.indices.items);

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
    self.vertex_buffer.unbind();
    self.index_buffer.unbind();
}

pub fn draw(self: *const Self, shader: Shader) void {
    if (self.material.ambient_map) |m| {
        m.bind(c.GL_TEXTURE0);
        shader.setUniform(i32, "ao_map", 0);
    }
    if (self.material.albedo_map) |m| {
        m.bind(c.GL_TEXTURE1);
        shader.setUniform(i32, "albedo_map", 1);
    }
    if (self.material.roughness_map) |m| {
        m.bind(c.GL_TEXTURE2);
        shader.setUniform(i32, "roughness_map", 2);
    }
    if (self.material.specular_map) |m| {
        m.bind(c.GL_TEXTURE3);
        shader.setUniform(i32, "metallic_map", 3);
    }
    if (self.material.normal_map) |m| {
        m.bind(c.GL_TEXTURE4);
        shader.setUniform(i32, "normal_map", 4);
    }

    c.glBindVertexArray(self.vao);
    c.glDrawElements(self.primitive, @intCast(self.indices.items.len), c.GL_UNSIGNED_SHORT, null);
    c.glBindVertexArray(0);
}
