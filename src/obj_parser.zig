const std = @import("std");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Model = @import("Model.zig");
const Vertex = @import("Vertex.zig");
const Mesh = @import("Mesh.zig");
const Material = @import("Material.zig");

const FaceType = enum {
    vertex_only,
    vertex_normal,
    vertex_uv,
    vertex_normal_uv,
};

const ObjVertex = union {
    vertex_only: struct { vertex: u32 },
    vertex_normal: struct { vertex: u32, normal: u32 },
    vertex_uv: struct { vertex: u32, uv: u32 },
    vertex_normal_uv: struct { vertex: u32, normal: u32, uv: u32 },
};

const ObjElementType = enum {
    vertex,
    uv,
    normal,
    face,
    object,
    group,
    use_material,
    material_lib,
    smooth_shading,
    comment,
    unknown,

    fn get(token: []const u8) ObjElementType {
        if (std.mem.eql(u8, token, "v")) return .vertex;
        if (std.mem.eql(u8, token, "vt")) return .uv;
        if (std.mem.eql(u8, token, "vn")) return .normal;
        if (std.mem.eql(u8, token, "f")) return .face;
        if (std.mem.eql(u8, token, "o")) return .object;
        if (std.mem.eql(u8, token, "g")) return .group;
        if (std.mem.eql(u8, token, "s")) return .smooth_shading;
        if (std.mem.eql(u8, token, "mtllib")) return .material_lib;
        if (std.mem.eql(u8, token, "usemtl")) return .use_material;
        if (std.mem.eql(u8, token, "#")) return .comment;
        return .unknown;
    }
};

const default_material = Material{
    .name = "default",
};

pub fn parseObj(allocator: std.mem.Allocator, filename: []const u8) !Model {
    const file = try std.fs.cwd().openFile(filename, .{});
    const file_content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    const dirname = std.fs.path.dirname(filename);
    _ = dirname;

    var vertices = std.ArrayList(Vec3).init(allocator);
    var normals = std.ArrayList(Vec3).init(allocator);
    var uvs = std.ArrayList(Vec2).init(allocator);

    var unique_vertices = std.AutoHashMap(ObjVertex, u64).init(allocator);

    var model = Model.init(allocator);
    try model.meshes.append(Mesh.init(allocator));

    const current_mesh = &model.meshes.items[0];
    current_mesh.material = &default_material;

    var lines = std.mem.splitAny(u8, file_content, "\r\n");
    var line_number: u64 = 0;
    while (lines.next()) |line| {
        line_number += 1;

        var tokens = std.mem.tokenizeAny(u8, line, "\r\n");
        const token = tokens.next() orelse continue; // Empty line

        const token_type = ObjElementType.get(token);

        switch (token_type) {
            .vertex => {},
            .uv => {},
            .normal => {},
            .face => {},
            .object => {},
            .group => {},
            .use_material => {},
            .material_lib => {},
            .smooth_shading => {},
            .comment => {},
            .unknown => {},
        }
    }
    _ = unique_vertices;
    _ = normals;
    _ = uvs;
    _ = vertices;
}
