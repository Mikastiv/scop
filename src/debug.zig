const std = @import("std");
const Mesh = @import("Mesh.zig");
const Vertex = @import("Vertex.zig");

pub fn createDebugPlane(allocator: std.mem.Allocator) !Mesh {
    var mesh = Mesh.init(allocator);

    const v0 = Vertex{
        .pos = .{ -2.0, 2.0, 0.0 },
        .normal = .{ 0.0, 0.0, 1.0 },
        .uv = .{ 0.0, 1.0 },
        .tangent = .{ 0.0, 0.0, 1.0 },
        .bitangent = .{ 0.0, 0.0, 1.0 },
    };
    const v1 = Vertex{
        .pos = .{ 2.0, 2.0, 0.0 },
        .normal = .{ 0.0, 0.0, 1.0 },
        .uv = .{ 1.0, 1.0 },
        .tangent = .{ 0.0, 0.0, 1.0 },
        .bitangent = .{ 0.0, 0.0, 1.0 },
    };
    const v2 = Vertex{
        .pos = .{ -2.0, -2.0, 0.0 },
        .normal = .{ 0.0, 0.0, 1.0 },
        .uv = .{ 0.0, 0.0 },
        .tangent = .{ 0.0, 0.0, 1.0 },
        .bitangent = .{ 0.0, 0.0, 1.0 },
    };
    const v3 = Vertex{
        .pos = .{ 2.0, -2.0, 0.0 },
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

    return mesh;
}
