const std = @import("std");

pub const Vec2 = [2]f32;
pub const Vec3 = [3]f32;
pub const Vec4 = [4]f32;
pub const Mat2 = [2]f32;
pub const Mat3 = [3]Vec3;
pub const Mat4 = [4]Vec4;

fn unsupportedType(comptime T: type) void {
    @compileError("unsupported type: " ++ @typeName(T));
}

pub fn veclen(comptime T: type) comptime_int {
    return @typeInfo(T).Array.len;
}

pub const vec = struct {
    pub inline fn sub(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
        return switch (@TypeOf(a)) {
            Vec2 => .{ a[0] - b[0], a[1] - b[1] },
            Vec3 => .{ a[0] - b[0], a[1] - b[1], a[2] - b[2] },
            Vec4 => .{ a[0] - b[0], a[1] - b[1], a[2] - b[2], a[3] - b[3] },
            else => unsupportedType(@TypeOf(a)),
        };
    }

    pub inline fn neg(v: anytype) @TypeOf(v) {
        return switch (@TypeOf(v)) {
            Vec2 => .{ -v[0], -v[1] },
            Vec3 => .{ -v[0], -v[1], -v[2] },
            Vec4 => .{ -v[0], -v[1], -v[2], -v[3] },
            else => unsupportedType(@TypeOf(v)),
        };
    }

    pub inline fn add(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
        return switch (@TypeOf(a)) {
            Vec2 => .{ a[0] + b[0], a[1] + b[1] },
            Vec3 => .{ a[0] + b[0], a[1] + b[1], a[2] + b[2] },
            Vec4 => .{ a[0] + b[0], a[1] + b[1], a[2] + b[2], a[3] + b[3] },
            else => unsupportedType(@TypeOf(a)),
        };
    }

    pub inline fn mul(a: anytype, b: f32) @TypeOf(a) {
        return switch (@TypeOf(a)) {
            Vec2 => .{ a[0] * b, a[1] * b },
            Vec3 => .{ a[0] * b, a[1] * b, a[2] * b },
            Vec4 => .{ a[0] * b, a[1] * b, a[2] * b, a[3] * b },
            else => unsupportedType(@TypeOf(a)),
        };
    }

    pub inline fn div(a: anytype, b: f32) @TypeOf(a) {
        return switch (@TypeOf(a)) {
            Vec2 => .{ a[0] / b, a[1] / b },
            Vec3 => .{ a[0] / b, a[1] / b, a[2] / b },
            Vec4 => .{ a[0] / b, a[1] / b, a[2] / b, a[3] / b },
            else => unsupportedType(@TypeOf(a)),
        };
    }

    pub inline fn length(v: anytype) f32 {
        return switch (@TypeOf(v)) {
            Vec2 => @sqrt(v[0] * v[0] + v[1] * v[1]),
            Vec3 => @sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]),
            Vec4 => @sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2] + v[3] * v[3]),
            else => unsupportedType(@TypeOf(v)),
        };
    }

    pub inline fn unit(v: anytype) @TypeOf(v) {
        const len = length(v);
        return switch (@TypeOf(v)) {
            Vec2 => .{ v[0] / len, v[1] / len },
            Vec3 => .{ v[0] / len, v[1] / len, v[2] / len },
            Vec4 => .{ v[0] / len, v[1] / len, v[2] / len, v[3] / len },
            else => unsupportedType(@TypeOf(v)),
        };
    }

    pub inline fn normalize(v: anytype) @TypeOf(v) {
        return unit(v);
    }

    pub inline fn dot(a: anytype, b: @TypeOf(a)) f32 {
        return switch (@TypeOf(a)) {
            Vec2 => a[0] * b[0] + a[1] * b[1],
            Vec3 => a[0] * b[0] + a[1] * b[1] + a[2] * b[2],
            Vec4 => a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3],
            else => unsupportedType(@TypeOf(a)),
        };
    }

    pub inline fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{
            a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0],
        };
    }
};

pub const mat = struct {
    pub inline fn identity(comptime T: type) T {
        return switch (T) {
            Mat2 => .{
                .{ 1, 0 },
                .{ 0, 1 },
            },
            Mat3 => .{
                .{ 1, 0, 0 },
                .{ 0, 1, 0 },
                .{ 0, 0, 1 },
            },
            Mat4 => .{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 0, 0, 0, 1 },
            },
            else => unsupportedType(T),
        };
    }

    pub inline fn add(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
        return switch (@TypeOf(a)) {
            Mat2 => .{
                vec.add(a[0], b[0]),
                vec.add(a[1], b[1]),
            },
            Mat3 => .{
                vec.add(a[0], b[0]),
                vec.add(a[1], b[1]),
                vec.add(a[2], b[2]),
            },
            Mat4 => .{
                vec.add(a[0], b[0]),
                vec.add(a[1], b[1]),
                vec.add(a[2], b[2]),
                vec.add(a[3], b[3]),
            },
            else => unsupportedType(@TypeOf(a)),
        };
    }

    pub inline fn sub(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
        return switch (@TypeOf(a)) {
            Mat2 => .{
                vec.sub(a[0], b[0]),
                vec.sub(a[1], b[1]),
            },
            Mat3 => .{
                vec.sub(a[0], b[0]),
                vec.sub(a[1], b[1]),
                vec.sub(a[2], b[2]),
            },
            Mat4 => .{
                vec.sub(a[0], b[0]),
                vec.sub(a[1], b[1]),
                vec.sub(a[2], b[2]),
                vec.sub(a[3], b[3]),
            },
            else => unsupportedType(@TypeOf(a)),
        };
    }

    pub inline fn mulScalar(a: anytype, b: f32) @TypeOf(a) {
        return switch (@TypeOf(a)) {
            Mat2 => .{
                vec.mul(a[0], b),
                vec.mul(a[1], b),
            },
            Mat3 => .{
                vec.mul(a[0], b),
                vec.mul(a[1], b),
                vec.mul(a[2], b),
            },
            Mat4 => .{
                vec.mul(a[0], b),
                vec.mul(a[1], b),
                vec.mul(a[2], b),
                vec.mul(a[3], b),
            },
            else => unsupportedType(@TypeOf(a)),
        };
    }

    pub inline fn mul(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
        return switch (@TypeOf(a)) {
            Mat2 => blk: {
                const a00 = a[0][0];
                const a01 = a[0][1];
                const a10 = a[1][0];
                const a11 = a[1][1];

                const b00 = b[0][0];
                const b01 = b[0][1];
                const b10 = b[1][0];
                const b11 = b[1][1];

                break :blk .{
                    .{
                        a00 * b00 + a10 * b01,
                        a01 * b00 + a11 * b01,
                    },
                    .{
                        a00 * b10 + a10 * b11,
                        a01 * b10 + a11 * b11,
                    },
                };
            },
            Mat3 => blk: {
                const a00 = a[0][0];
                const a01 = a[0][1];
                const a02 = a[0][2];
                const a10 = a[1][0];
                const a11 = a[1][1];
                const a12 = a[1][2];
                const a20 = a[2][0];
                const a21 = a[2][1];
                const a22 = a[2][2];

                const b00 = b[0][0];
                const b01 = b[0][1];
                const b02 = b[0][2];
                const b10 = b[1][0];
                const b11 = b[1][1];
                const b12 = b[1][2];
                const b20 = b[2][0];
                const b21 = b[2][1];
                const b22 = b[2][2];

                break :blk .{
                    .{
                        a00 * b00 + a10 * b01 + a20 * b02,
                        a01 * b00 + a11 * b01 + a21 * b02,
                        a02 * b00 + a12 * b01 + a22 * b02,
                    },
                    .{
                        a00 * b10 + a10 * b11 + a20 * b12,
                        a01 * b10 + a11 * b11 + a21 * b12,
                        a02 * b10 + a12 * b11 + a22 * b12,
                    },
                    .{
                        a00 * b20 + a10 * b21 + a20 * b22,
                        a01 * b20 + a11 * b21 + a21 * b22,
                        a02 * b20 + a12 * b21 + a22 * b22,
                    },
                };
            },
            Mat4 => blk: {
                const a00 = a[0][0];
                const a01 = a[0][1];
                const a02 = a[0][2];
                const a03 = a[0][3];
                const a10 = a[1][0];
                const a11 = a[1][1];
                const a12 = a[1][2];
                const a13 = a[1][3];
                const a20 = a[2][0];
                const a21 = a[2][1];
                const a22 = a[2][2];
                const a23 = a[2][3];
                const a30 = a[3][0];
                const a31 = a[3][1];
                const a32 = a[3][2];
                const a33 = a[3][3];

                const b00 = b[0][0];
                const b01 = b[0][1];
                const b02 = b[0][2];
                const b03 = b[0][3];
                const b10 = b[1][0];
                const b11 = b[1][1];
                const b12 = b[1][2];
                const b13 = b[1][3];
                const b20 = b[2][0];
                const b21 = b[2][1];
                const b22 = b[2][2];
                const b23 = b[2][3];
                const b30 = b[3][0];
                const b31 = b[3][1];
                const b32 = b[3][2];
                const b33 = b[3][3];

                break :blk .{
                    .{
                        a00 * b00 + a10 * b01 + a20 * b02 + a30 * b03,
                        a01 * b00 + a11 * b01 + a21 * b02 + a31 * b03,
                        a02 * b00 + a12 * b01 + a22 * b02 + a32 * b03,
                        a03 * b00 + a13 * b01 + a23 * b02 + a33 * b03,
                    },
                    .{
                        a00 * b10 + a10 * b11 + a20 * b12 + a30 * b13,
                        a01 * b10 + a11 * b11 + a21 * b12 + a31 * b13,
                        a02 * b10 + a12 * b11 + a22 * b12 + a32 * b13,
                        a03 * b10 + a13 * b11 + a23 * b12 + a33 * b13,
                    },
                    .{
                        a00 * b20 + a10 * b21 + a20 * b22 + a30 * b23,
                        a01 * b20 + a11 * b21 + a21 * b22 + a31 * b23,
                        a02 * b20 + a12 * b21 + a22 * b22 + a32 * b23,
                        a03 * b20 + a13 * b21 + a23 * b22 + a33 * b23,
                    },
                    .{
                        a00 * b30 + a10 * b31 + a20 * b32 + a30 * b33,
                        a01 * b30 + a11 * b31 + a21 * b32 + a31 * b33,
                        a02 * b30 + a12 * b31 + a22 * b32 + a32 * b33,
                        a03 * b30 + a13 * b31 + a23 * b32 + a33 * b33,
                    },
                };
            },
            else => unsupportedType(@TypeOf(a)),
        };
    }

    pub inline fn scaling(s: Vec3) Mat4 {
        return .{
            .{ s[0], 0, 0, 0 },
            .{ 0, s[1], 0, 0 },
            .{ 0, 0, s[2], 0 },
            .{ 0, 0, 0, 1 },
        };
    }

    pub inline fn scalingScalar(s: f32) Mat4 {
        return scaling(.{ s, s, s });
    }

    pub inline fn scale(m: *const Mat4, s: Vec3) Mat4 {
        var out = m.*;
        out[0] = vec.mul(m.*[0], s[0]);
        out[1] = vec.mul(m.*[1], s[1]);
        out[2] = vec.mul(m.*[2], s[2]);
        out[3] = m.*[3];
        return out;
    }

    pub inline fn scaleScalar(m: *const Mat4, s: f32) Mat4 {
        return scale(m, .{ s, s, s });
    }

    pub inline fn translation(t: Vec3) Mat4 {
        return .{
            .{ 1, 0, 0, 0 },
            .{ 0, 1, 0, 0 },
            .{ 0, 0, 1, 0 },
            .{ t[0], t[1], t[2], 1 },
        };
    }

    pub inline fn translate(m: *const Mat4, t: Vec3) Mat4 {
        return mul(m.*, translation(t));
    }

    pub inline fn rotation(angle: f32, axis: Vec3) Mat4 {
        const s = @sin(angle);
        const c = @cos(angle);
        const a = vec.unit(axis);
        const t = vec.mul(a, 1.0 - c);

        return .{
            .{ c + t[0] * a[0], t[0] * a[1] + s * a[2], t[0] * a[2] - s * a[1], 0 },
            .{ t[1] * a[0] - s * a[2], c + t[1] * a[1], t[1] * a[2] + s * a[0], 0 },
            .{ t[2] * a[0] + s * a[1], t[2] * a[1] - s * a[0], c + t[2] * a[2], 0 },
            .{ 0, 0, 0, 1 },
        };
    }

    pub inline fn rotate(m: *const Mat4, angle: f32, axis: Vec3) Mat4 {
        return mul(m.*, rotation(angle, axis));
    }

    pub inline fn perspective(fovy: f32, aspect: f32, near: f32, far: f32) Mat4 {
        std.debug.assert(near > 0 and far > 0);

        const h = @tan(fovy / 2.0);
        const r = near - far;

        return .{
            .{ 1.0 / (aspect * h), 0.0, 0.0, 0.0 },
            .{ 0.0, 1.0 / h, 0.0, 0.0 },
            .{ 0.0, 0.0, -(far + near) / r, -1.0 },
            .{ 0.0, 0.0, -2.0 * far * near / r, 0.0 },
        };
    }

    pub inline fn lookAt(eye: Vec3, target: Vec3, up: Vec3) Mat4 {
        const zaxis = vec.normalize(vec.sub(target, eye));
        const xaxis = vec.normalize(vec.cross(up, zaxis));
        const yaxis = vec.cross(zaxis, xaxis);

        const t = translation(vec.neg(eye));
        const r = Mat4{
            .{ -xaxis[0], yaxis[0], -zaxis[0], 0 },
            .{ -xaxis[1], yaxis[1], -zaxis[1], 0 },
            .{ -xaxis[2], yaxis[2], -zaxis[2], 0 },
            .{ 0, 0, 0, 1 },
        };

        return mat.mul(r, t);
    }
};
