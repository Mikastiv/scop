const std = @import("std");
const Mesh = @import("Mesh.zig");
const Vertex = @import("Vertex.zig");
const math = @import("math.zig");
const c = @import("c.zig");

fn addVertex(vertices: *std.ArrayList(Vertex), x: f32, y: f32, z: f32) !void {
    const pos = math.vec.normalize(math.Vec3{ x, y, z });
    try vertices.append(.{
        .pos = pos,
        .normal = pos,
        .uv = .{ 0, 0 },
        .tangent = pos,
        .bitangent = pos,
    });
}

fn addMiddlePoint(
    idx_cache: *const std.AutoHashMap(u32, u16),
    vertices: *std.ArrayList(Vertex),
    p0: u16,
    p1: u16,
) !u16 {
    const key = (@as(u32, p0) << 16) + p1;
    if (idx_cache.get(key)) |idx| return idx;

    const mid = math.vec.div(math.vec.add(vertices.items[p0].pos, vertices.items[p1].pos), 2.0);
    const new_idx = vertices.items.len;
    try addVertex(vertices, mid[0], mid[1], mid[2]);

    return @truncate(new_idx);
}

pub fn generateIcosphere(allocator: std.mem.Allocator, tessellation: u32) !Mesh {
    var mesh = Mesh.init(allocator);

    const t = (1.0 + @sqrt(5.0)) / 2.0;

    try addVertex(&mesh.vertices, -1, t, 0);
    try addVertex(&mesh.vertices, 1, t, 0);
    try addVertex(&mesh.vertices, -1, -t, 0);
    try addVertex(&mesh.vertices, 1, -t, 0);

    try addVertex(&mesh.vertices, 0, -1, t);
    try addVertex(&mesh.vertices, 0, 1, t);
    try addVertex(&mesh.vertices, 0, -1, -t);
    try addVertex(&mesh.vertices, 0, 1, -t);

    try addVertex(&mesh.vertices, t, 0, -1);
    try addVertex(&mesh.vertices, t, 0, 1);
    try addVertex(&mesh.vertices, -t, 0, -1);
    try addVertex(&mesh.vertices, -t, 0, 1);

    try mesh.indices.appendSlice(&.{ 0, 11, 5 });
    try mesh.indices.appendSlice(&.{ 0, 5, 1 });
    try mesh.indices.appendSlice(&.{ 0, 1, 7 });
    try mesh.indices.appendSlice(&.{ 0, 7, 10 });
    try mesh.indices.appendSlice(&.{ 0, 10, 11 });

    try mesh.indices.appendSlice(&.{ 1, 5, 9 });
    try mesh.indices.appendSlice(&.{ 5, 11, 4 });
    try mesh.indices.appendSlice(&.{ 11, 10, 2 });
    try mesh.indices.appendSlice(&.{ 10, 7, 6 });
    try mesh.indices.appendSlice(&.{ 7, 1, 8 });

    try mesh.indices.appendSlice(&.{ 3, 9, 4 });
    try mesh.indices.appendSlice(&.{ 3, 4, 2 });
    try mesh.indices.appendSlice(&.{ 3, 2, 6 });
    try mesh.indices.appendSlice(&.{ 3, 6, 8 });
    try mesh.indices.appendSlice(&.{ 3, 8, 9 });

    try mesh.indices.appendSlice(&.{ 4, 9, 5 });
    try mesh.indices.appendSlice(&.{ 2, 4, 11 });
    try mesh.indices.appendSlice(&.{ 6, 2, 10 });
    try mesh.indices.appendSlice(&.{ 8, 6, 7 });
    try mesh.indices.appendSlice(&.{ 9, 8, 1 });

    var idx_cache = std.AutoHashMap(u32, u16).init(allocator);
    defer idx_cache.deinit();

    for (0..tessellation) |_| {
        var new_idxs = std.ArrayList(u16).init(allocator);

        var idx: u32 = 0;
        while (idx < mesh.indices.items.len) : (idx += 3) {
            const p1 = try addMiddlePoint(
                &idx_cache,
                &mesh.vertices,
                mesh.indices.items[idx],
                mesh.indices.items[idx + 1],
            );
            const p2 = try addMiddlePoint(
                &idx_cache,
                &mesh.vertices,
                mesh.indices.items[idx + 1],
                mesh.indices.items[idx + 2],
            );
            const p3 = try addMiddlePoint(
                &idx_cache,
                &mesh.vertices,
                mesh.indices.items[idx + 2],
                mesh.indices.items[idx],
            );

            try new_idxs.appendSlice(&.{ mesh.indices.items[idx], p1, p3 });
            try new_idxs.appendSlice(&.{ mesh.indices.items[idx + 1], p2, p1 });
            try new_idxs.appendSlice(&.{ mesh.indices.items[idx + 2], p3, p2 });
            try new_idxs.appendSlice(&.{ p1, p2, p3 });
        }

        mesh.indices.deinit();
        mesh.indices = new_idxs;
    }

    return mesh;
}

pub fn generateSphere(allocator: std.mem.Allocator, latitude_segments: u32, longitude_segments: u32) !Mesh {
    var mesh = Mesh.init(allocator);
    mesh.primitive = c.GL_TRIANGLE_STRIP;

    for (0..longitude_segments + 1) |x| {
        for (0..latitude_segments + 1) |y| {
            const x_segment = @as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(longitude_segments));
            const y_segment = @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(latitude_segments));
            const x_pos = @cos(x_segment * std.math.tau) * @sin(y_segment * std.math.pi);
            const y_pos = @cos(y_segment * std.math.pi);
            const z_pos = @sin(x_segment * std.math.tau) * @sin(y_segment * std.math.pi);

            try mesh.vertices.append(.{
                .pos = .{ x_pos, y_pos, z_pos },
                .normal = .{ x_pos, y_pos, z_pos },
                .uv = .{ x_segment, y_segment },
                .tangent = .{ x_pos, y_pos, z_pos }, // TODO: proper tangent
                .bitangent = .{ x_pos, y_pos, z_pos }, // TODO: proper bitangent
            });
        }
    }

    var odd_row = false;
    for (0..longitude_segments) |y| {
        if (!odd_row) {
            for (0..latitude_segments + 1) |x| {
                try mesh.indices.append(@intCast(y * (latitude_segments + 1) + x));
                try mesh.indices.append(@intCast((y + 1) * (latitude_segments + 1) + x));
            }
        } else {
            var x = latitude_segments + 1;
            for (0..latitude_segments + 1) |_| {
                x -= 1;
                try mesh.indices.append(@intCast((y + 1) * (latitude_segments + 1) + x));
                try mesh.indices.append(@intCast(y * (latitude_segments + 1) + x));
            }
        }
        odd_row = !odd_row;
    }

    return mesh;
}
