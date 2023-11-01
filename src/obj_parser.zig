const std = @import("std");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Model = @import("Model.zig");
const Vertex = @import("Vertex.zig");
const Mesh = @import("Mesh.zig");
const Material = @import("Material.zig");

const Triangle = struct {
    vertices: [3]u32,
    uvs: [3]u32,
    normals: [3]u32,
};

const Face = struct {
    const max_size = 32;
    vertices: [max_size]u32 = std.mem.zeroes([max_size]u32),
    uvs: [max_size]u32 = std.mem.zeroes([max_size]u32),
    normals: [max_size]u32 = std.mem.zeroes([max_size]u32),
    len: u32 = 0,
};

const FaceType = enum {
    vertex_only,
    vertex_normal,
    vertex_uv,
    vertex_normal_uv,

    fn fromStr(str: []const u8) error{InvalidFaceFormat}!FaceType {
        var it = std.mem.splitScalar(u8, str, '/');

        const has_v = it.next() != null;
        const has_vt = it.peek() != null and !std.mem.eql(u8, it.next().?, "");
        const has_vn = it.next() != null;

        if (has_v and has_vt and has_vn) return .vertex_normal_uv;
        if (has_v and has_vt and !has_vn) return .vertex_uv;
        if (has_v and !has_vt and has_vn) return .vertex_normal;
        if (has_v and !has_vt and !has_vn) return .vertex_only;
        return error.InvalidFaceFormat;
    }
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

    fn fromStr(str: []const u8) ObjElementType {
        if (std.mem.eql(u8, str, "v")) return .vertex;
        if (std.mem.eql(u8, str, "vt")) return .uv;
        if (std.mem.eql(u8, str, "vn")) return .normal;
        if (std.mem.eql(u8, str, "f")) return .face;
        if (std.mem.eql(u8, str, "o")) return .object;
        if (std.mem.eql(u8, str, "g")) return .group;
        if (std.mem.eql(u8, str, "s")) return .smooth_shading;
        if (std.mem.eql(u8, str, "mtllib")) return .material_lib;
        if (std.mem.eql(u8, str, "usemtl")) return .use_material;
        if (std.mem.eql(u8, str, "#")) return .comment;
        return .unknown;
    }
};

const default_material = Material{
    .name = "default",
};

fn parseVec(comptime VecT: type, tokens: std.mem.TokenIterator(u8, .any)) !VecT {
    var it = tokens;

    const len = @typeInfo(VecT).Vector.len;
    var v: VecT = switch (len) {
        2 => math.vec2.init(0, 0),
        3 => math.vec3.init(0, 0, 0),
        else => @compileError("Unsupported vector length"),
    };

    for (0..len) |i| {
        const token = it.next() orelse return error.NotEnoughVecElements;
        v[i] = try std.fmt.parseFloat(f32, token);
    }
    return v;
}

fn parseFace(tokens: std.mem.TokenIterator(u8, .any), face_type: FaceType) !Face {
    var face = Face{};

    var i = 0;
    while (i < Face.max_size) : (i += 1) {
        const token = tokens.next() orelse break;
        var it = std.mem.tokenizeScalar(u8, token, '/');
        switch (face_type) {
            .vertex_only => face.vertices[i] = try std.fmt.parseInt(u32, token, 10) - 1,
            .vertex_normal => {
                const v = it.next() orelse return error.ParseError;
                const n = it.next() orelse return error.ParseError;
                if (it.next() != null) return error.ParseError;

                face.vertices[i] = try std.fmt.parseInt(u32, v, 10) - 1;
                face.normals[i] = try std.fmt.parseInt(u32, n, 10) - 1;
            },
            .vertex_uv => {
                const v = it.next() orelse return error.ParseError;
                const u = it.next() orelse return error.ParseError;
                if (it.next() != null) return error.ParseError;

                face.vertices[i] = try std.fmt.parseInt(u32, v, 10) - 1;
                face.uvs[i] = try std.fmt.parseInt(u32, u, 10) - 1;
            },
            .vertex_normal_uv => {
                const v = it.next() orelse return error.ParseError;
                const u = it.next() orelse return error.ParseError;
                const n = it.next() orelse return error.ParseError;
                if (it.next() != null) return error.ParseError;

                face.vertices[i] = try std.fmt.parseInt(u32, v, 10) - 1;
                face.uvs[i] = try std.fmt.parseInt(u32, u, 10) - 1;
                face.normals[i] = try std.fmt.parseInt(u32, n, 10) - 1;
            },
        }
    }

    face.len = i;
    return face;
}

fn makeError(comptime msg: []const u8, line_number: u64) error{ParseError} {
    std.log.err(msg ++ " (line: {d})", .{line_number});
    return error.ParseError;
}

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

        var tokens = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);
        const token = tokens.next() orelse continue; // Empty line

        const token_type = ObjElementType.fromStr(token);

        switch (token_type) {
            .vertex => {
                const vec = parseVec(math.Vec3, tokens) catch
                    return makeError("error reading vertex", line_number);
                try vertices.append(vec);
            },
            .uv => {
                const vec = parseVec(math.Vec2, tokens) catch
                    return makeError("error reading uv", line_number);
                try uvs.append(vec);
            },
            .normal => {
                const vec = parseVec(math.Vec3, tokens) catch
                    return makeError("error reading normal", line_number);
                try normals.append(vec);
            },
            .face => {
                const next_token = tokens.peek() orelse
                    return makeError("error reading face", line_number);

                const face_type = try FaceType.fromStr(next_token);
                const face = parseFace(tokens, face_type) catch
                    return makeError("error reading face", line_number);
                if (face.len < 3 or face.len > 4)
                    return makeError("unsupported face size", line_number);

                var triangles = std.ArrayList(Triangle).initCapacity(allocator, face.len - 2);
                _ = triangles;
            },
            .object => current_mesh.name = tokens.rest(),
            .group => {},
            .use_material => {},
            .material_lib => {},
            .smooth_shading => {},
            .comment => {},
            .unknown => std.log.warn("unknown token \"{s}\" (line {d})", .{ token, line_number }),
        }
    }

    _ = unique_vertices;

    return model;
}
