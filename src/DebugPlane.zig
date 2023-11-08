const Self = @This();
const std = @import("std");
const Mesh = @import("Mesh.zig");
const Vertex = @import("Vertex.zig");
const Shader = @import("Shader.zig");
const Texture = @import("Texture.zig");
const bmp = @import("bmp.zig");
const math = @import("math.zig");
const c = @import("c.zig");

mesh: Mesh,
shader: Shader,
texture: Texture,

pub fn init(allocator: std.mem.Allocator, image_file: []const u8) !Self {
    var mesh = Mesh.init(allocator);
    errdefer mesh.deinit();

    const v0 = Vertex{
        .pos = .{ -1.0, 1.0, 0.0 },
        .normal = .{ 0.0, 0.0, 1.0 },
        .uv = .{ 0.0, 1.0 },
        .tangent = .{ 0.0, 0.0, 1.0 },
        .bitangent = .{ 0.0, 0.0, 1.0 },
    };
    const v1 = Vertex{
        .pos = .{ 1.0, 1.0, 0.0 },
        .normal = .{ 0.0, 0.0, 1.0 },
        .uv = .{ 1.0, 1.0 },
        .tangent = .{ 0.0, 0.0, 1.0 },
        .bitangent = .{ 0.0, 0.0, 1.0 },
    };
    const v2 = Vertex{
        .pos = .{ -1.0, -1.0, 0.0 },
        .normal = .{ 0.0, 0.0, 1.0 },
        .uv = .{ 0.0, 0.0 },
        .tangent = .{ 0.0, 0.0, 1.0 },
        .bitangent = .{ 0.0, 0.0, 1.0 },
    };
    const v3 = Vertex{
        .pos = .{ 1.0, -1.0, 0.0 },
        .normal = .{ 0.0, 0.0, 1.0 },
        .uv = .{ 1.0, 0.0 },
        .tangent = .{ 0.0, 0.0, 1.0 },
        .bitangent = .{ 0.0, 0.0, 1.0 },
    };

    try mesh.vertices.append(v0);
    try mesh.vertices.append(v1);
    try mesh.vertices.append(v2);
    try mesh.vertices.append(v3);

    try mesh.indices.appendSlice(&.{ 0, 2, 1 });
    try mesh.indices.appendSlice(&.{ 1, 2, 3 });

    mesh.loadOnGpu();

    const shader = try Shader.init(allocator, "shaders/debug.vert", "shaders/debug.frag");
    errdefer shader.deinit();

    const image = try bmp.load(allocator, image_file, false);
    defer allocator.free(image.pixels);
    const texture = Texture{ .image = image };

    return .{
        .mesh = mesh,
        .shader = shader,
        .texture = texture,
    };
}

pub fn deinit(self: *const Self) void {
    self.mesh.deinit();
    self.shader.deinit();
}

pub fn draw(self: *const Self) void {
    self.shader.use();

    var model = math.mat.identity(math.Mat4);
    model = math.mat.translate(&model, .{ -0.5, 0.5, 0 });
    model = math.mat.scaleScalar(&model, 0.5);
    self.shader.setUniform(math.Mat4, "model", model);

    self.texture.bind(c.GL_TEXTURE0);
    self.shader.setUniform(i32, "tex", 0);

    self.mesh.draw();
}
