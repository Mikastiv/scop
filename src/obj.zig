const std = @import("std");
const math = @import("math.zig");
const vec = math.vec;
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

const ObjVertex = struct {
    face_type: FaceType,
    vertex: u32,
    normal: u32,
    uv: u32,
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

fn parseVec(comptime VecT: type, tokens: std.mem.TokenIterator(u8, .any)) !VecT {
    var it = tokens;

    const len = math.veclen(VecT);
    var v: VecT = switch (len) {
        2 => .{ 0, 0 },
        3 => .{ 0, 0, 0 },
        else => @compileError("Unsupported vector length"),
    };

    for (0..len) |i| {
        const token = it.next() orelse return error.NotEnoughVecElements;
        v[i] = try std.fmt.parseFloat(f32, token);
    }
    return v;
}

fn containsNormals(face_type: FaceType) bool {
    return face_type == .vertex_normal or face_type == .vertex_normal_uv;
}

fn containsUVs(face_type: FaceType) bool {
    return face_type == .vertex_uv or face_type == .vertex_normal_uv;
}

fn parseFace(tokens: std.mem.TokenIterator(u8, .any), face_type: FaceType) !Face {
    var tokens_it = tokens;
    var face = Face{};

    var i: u32 = 0;
    while (i < Face.max_size) : (i += 1) {
        const token = tokens_it.next() orelse break;
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

fn faceToTriangles(allocator: std.mem.Allocator, face: Face) !std.ArrayList(Triangle) {
    var triangles = try std.ArrayList(Triangle).initCapacity(allocator, face.len - 2);

    if (face.len == 3) {
        const tri = Triangle{
            .vertices = .{ face.vertices[0], face.vertices[1], face.vertices[2] },
            .uvs = .{ face.uvs[0], face.uvs[1], face.uvs[2] },
            .normals = .{ face.normals[0], face.normals[1], face.normals[2] },
        };
        try triangles.append(tri);
    } else {
        const tri1 = Triangle{
            .vertices = .{ face.vertices[0], face.vertices[1], face.vertices[3] },
            .uvs = .{ face.uvs[0], face.uvs[1], face.uvs[3] },
            .normals = .{ face.normals[0], face.normals[1], face.normals[3] },
        };
        const tri2 = Triangle{
            .vertices = .{ face.vertices[3], face.vertices[1], face.vertices[2] },
            .uvs = .{ face.uvs[3], face.uvs[1], face.uvs[2] },
            .normals = .{ face.normals[3], face.normals[1], face.normals[2] },
        };

        try triangles.append(tri1);
        try triangles.append(tri2);
    }

    return triangles;
}

fn makeError(comptime msg: []const u8, line_number: u32) error{ParseError} {
    std.log.err(msg ++ " (line: {d})", .{line_number});
    return error.ParseError;
}

fn newlineToken(str: []const u8) []const u8 {
    return if (std.mem.indexOf(u8, str, "\r\n")) |_| "\r\n" else "\n";
}

pub fn parseObj(allocator: std.mem.Allocator, filename: []const u8) !Model {
    const file = try std.fs.cwd().openFile(filename, .{});
    const dirname = std.fs.path.dirname(filename) orelse ".";
    const file_content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_content);

    var vertices = std.ArrayList(Vec3).init(allocator);
    defer vertices.deinit();
    var normals = std.ArrayList(Vec3).init(allocator);
    defer vertices.deinit();
    var uvs = std.ArrayList(Vec2).init(allocator);
    defer uvs.deinit();

    var unique_vertices = std.AutoHashMap(ObjVertex, u16).init(allocator);
    defer unique_vertices.deinit();

    var model = Model.init(allocator);
    try model.meshes.append(Mesh.init(allocator));
    errdefer model.deinit();

    const current_mesh = &model.meshes.items[0];

    var lines = std.mem.splitSequence(u8, file_content, newlineToken(file_content));
    var line_number: u32 = 0;
    while (lines.next()) |line| {
        line_number += 1;

        var tokens = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);
        const token = tokens.next() orelse continue; // Empty line

        const token_type = ObjElementType.fromStr(token);
        switch (token_type) {
            .vertex => {
                const v = parseVec(Vec3, tokens) catch return makeError("error reading vertex", line_number);
                try vertices.append(v);
            },
            .uv => {
                const v = parseVec(Vec2, tokens) catch return makeError("error reading uv", line_number);
                try uvs.append(v);
            },
            .normal => {
                const v = parseVec(Vec3, tokens) catch return makeError("error reading normal", line_number);
                try normals.append(v);
            },
            .face => {
                const next_token = tokens.peek() orelse return makeError("error reading face", line_number);

                const face_type = try FaceType.fromStr(next_token);
                const face = parseFace(tokens, face_type) catch return makeError("error reading face", line_number);
                if (face.len < 3 or face.len > 4) return makeError("unsupported face size", line_number);

                const triangles = try faceToTriangles(allocator, face);
                defer triangles.deinit();
                for (triangles.items) |tri| {
                    // vertex indices
                    const v_idxs = [_]u32{ tri.vertices[0], tri.vertices[1], tri.vertices[2] };
                    const v_size = vertices.items.len;

                    // uv indices
                    const vt_idxs = [_]u32{ tri.uvs[0], tri.uvs[1], tri.uvs[2] };
                    const vt_size = uvs.items.len;

                    // normal indices
                    const vn_idxs = [_]u32{ tri.normals[0], tri.normals[1], tri.normals[2] };
                    const vn_size = normals.items.len;

                    if (v_idxs[0] >= v_size or v_idxs[1] >= v_size or v_idxs[2] >= v_size)
                        return makeError("invalid vertex index", line_number);
                    if (containsUVs(face_type) and (vt_idxs[0] >= vt_size or vt_idxs[1] >= vt_size or vt_idxs[2] >= vt_size))
                        return makeError("invalid uv index", line_number);
                    if (containsNormals(face_type) and (vn_idxs[0] >= vn_size or vn_idxs[1] >= vn_size or vn_idxs[2] >= vn_size))
                        return makeError("invalid normal index", line_number);

                    const obj_verts = [_]ObjVertex{
                        .{
                            .face_type = face_type,
                            .vertex = v_idxs[0],
                            .uv = vt_idxs[0],
                            .normal = vn_idxs[0],
                        },
                        .{
                            .face_type = face_type,
                            .vertex = v_idxs[1],
                            .uv = vt_idxs[1],
                            .normal = vn_idxs[1],
                        },
                        .{
                            .face_type = face_type,
                            .vertex = v_idxs[2],
                            .uv = vt_idxs[2],
                            .normal = vn_idxs[2],
                        },
                    };

                    const idxs = [_]?u16{
                        unique_vertices.get(obj_verts[0]),
                        unique_vertices.get(obj_verts[1]),
                        unique_vertices.get(obj_verts[2]),
                    };

                    // vertices
                    const vs = [_]Vec3{
                        vertices.items[v_idxs[0]],
                        vertices.items[v_idxs[1]],
                        vertices.items[v_idxs[2]],
                    };

                    // uvs
                    var vts: [3]Vec2 = undefined;
                    if (containsUVs(face_type)) {
                        vts[0] = uvs.items[vt_idxs[0]];
                        vts[1] = uvs.items[vt_idxs[1]];
                        vts[2] = uvs.items[vt_idxs[2]];
                    } else {
                        vts[0] = .{ vs[0][2], vs[0][1] };
                        vts[1] = .{ vs[1][2], vs[1][1] };
                        vts[2] = .{ vs[2][2], vs[2][1] };
                    }

                    // normals
                    var vns: [3]Vec3 = undefined;
                    if (containsNormals(face_type)) {
                        vns[0] = normals.items[0];
                        vns[1] = normals.items[1];
                        vns[2] = normals.items[2];
                    } else {
                        const a = vec.sub(vs[1], vs[0]);
                        const b = vec.sub(vs[2], vs[0]);
                        const n = vec.normalize(vec.cross(a, b));
                        vns[0] = n;
                        vns[1] = n;
                        vns[2] = n;
                    }

                    // tangent & bitangent
                    const edge1 = vec.sub(vs[1], vs[0]);
                    const edge2 = vec.sub(vs[2], vs[0]);
                    const d_uv1 = vec.sub(vts[1], vts[0]);
                    const d_uv2 = vec.sub(vts[2], vts[0]);
                    const f = 1.0 / (d_uv1[0] * d_uv2[1] - d_uv2[0] * d_uv1[1]);

                    const tangent = Vec3{
                        f * (d_uv2[1] * edge1[0] - d_uv1[1] * edge2[0]),
                        f * (d_uv2[1] * edge1[1] - d_uv1[1] * edge2[1]),
                        f * (d_uv2[1] * edge1[2] - d_uv1[1] * edge2[2]),
                    };
                    const bitangent = Vec3{
                        f * (-d_uv2[1] * edge1[0] + d_uv1[1] * edge2[0]),
                        f * (-d_uv2[1] * edge1[1] + d_uv1[1] * edge2[1]),
                        f * (-d_uv2[1] * edge1[2] + d_uv1[1] * edge2[2]),
                    };

                    const verts = [_]Vertex{
                        .{ .pos = vs[0], .normal = vns[0], .uv = vts[0], .tangent = tangent, .bitangent = bitangent },
                        .{ .pos = vs[1], .normal = vns[1], .uv = vts[1], .tangent = tangent, .bitangent = bitangent },
                        .{ .pos = vs[2], .normal = vns[2], .uv = vts[2], .tangent = tangent, .bitangent = bitangent },
                    };

                    for (0..3) |i| {
                        var current_idx: u16 = undefined;
                        if (idxs[i] == null) {
                            current_idx = @truncate(current_mesh.vertices.items.len);
                            try current_mesh.vertices.append(verts[i]);
                            try unique_vertices.putNoClobber(obj_verts[i], @truncate(current_idx));
                        } else {
                            current_idx = idxs[i].?;
                        }
                        try current_mesh.indices.append(@truncate(current_idx));
                    }
                }
            },
            .object => current_mesh.name = std.mem.trim(u8, tokens.rest(), &std.ascii.whitespace),
            .group => {},
            .use_material => {},
            .material_lib => {
                const mtl_filename = std.mem.trim(u8, tokens.rest(), &std.ascii.whitespace);
                const new_materials = try loadMaterials(allocator, dirname, mtl_filename);
                defer allocator.free(new_materials);
                try model.materials.appendSlice(new_materials);
            },
            .smooth_shading => {},
            .comment => {},
            .unknown => std.log.warn("unknown token \"{s}\" (line {d})", .{ token, line_number }),
        }
    }

    return model;
}

const MaterialElementType = enum {
    new_material,
    ambient_color,
    diffuse_color,
    specular_color,
    comment,
    unknown,

    fn fromStr(str: []const u8) MaterialElementType {
        if (std.mem.eql(u8, str, "newmtl")) return .new_material;
        if (std.mem.eql(u8, str, "Ka")) return .ambient_color;
        if (std.mem.eql(u8, str, "Kd")) return .diffuse_color;
        if (std.mem.eql(u8, str, "Ks")) return .specular_color;
        if (std.mem.eql(u8, str, "#")) return .comment;
        return .unknown;
    }
};

fn loadMaterials(allocator: std.mem.Allocator, dirname: []const u8, filename: []const u8) ![]Material {
    const filepath = try std.mem.join(allocator, "/", &.{ dirname, filename });
    defer allocator.free(filepath);
    const file = try std.fs.cwd().openFile(filepath, .{});
    const file_content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(file_content);

    var materials = std.ArrayList(Material).init(allocator);

    var current_material: ?*Material = null;

    var lines = std.mem.splitSequence(u8, file_content, newlineToken(file_content));
    var line_number: u32 = 0;
    while (lines.next()) |line| {
        line_number += 1;

        var tokens = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);
        const token = tokens.next() orelse continue; // Empty line

        const token_type = MaterialElementType.fromStr(token);

        if (current_material == null and token_type != .new_material and token_type != .comment)
            return makeError("material defined without a name", line_number);

        switch (token_type) {
            .new_material => {
                try materials.append(Material{});
                current_material = &materials.items[0];
                current_material.?.name = std.mem.trim(u8, tokens.rest(), &std.ascii.whitespace);
            },
            .ambient_color => current_material.?.ambient = parseVec(Vec3, tokens) catch
                return makeError("error reading ambient color", line_number),
            .diffuse_color => current_material.?.diffuse = parseVec(Vec3, tokens) catch
                return makeError("error reading diffuse color", line_number),
            .specular_color => current_material.?.specular = parseVec(Vec3, tokens) catch
                return makeError("error reading specular color", line_number),
            .comment => {},
            .unknown => std.log.warn("unknown token \"{s}\" (line {d})", .{ token, line_number }),
        }
    }

    return materials.toOwnedSlice();
}
