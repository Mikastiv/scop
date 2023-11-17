const std = @import("std");

pub const Vec2 = [2]f32;
pub const Vec3 = [3]f32;
pub const Vec4 = [4]f32;
pub const Mat2 = [2]Vec2;
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

    pub inline fn length2(v: anytype) f32 {
        return switch (@TypeOf(v)) {
            Vec2 => v[0] * v[0] + v[1] * v[1],
            Vec3 => v[0] * v[0] + v[1] * v[1] + v[2] * v[2],
            Vec4 => v[0] * v[0] + v[1] * v[1] + v[2] * v[2] + v[3] * v[3],
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
            (a[1] * b[2]) - (a[2] * b[1]),
            (a[2] * b[0]) - (a[0] * b[2]),
            (a[0] * b[1]) - (a[1] * b[0]),
        };
    }

    pub inline fn distance(a: anytype, b: @TypeOf(a)) f32 {
        return switch (@TypeOf(a)) {
            Vec2, Vec3, Vec4 => length(sub(a, b)),
            else => unsupportedType(@TypeOf(a)),
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
        switch (@TypeOf(a)) {
            Mat2, Mat3, Mat4 => {},
            else => unsupportedType(@TypeOf(a)),
        }

        const row_len = veclen(@TypeOf(a[0]));
        const col_len = a.len;

        var out: @TypeOf(a) = undefined;
        inline for (0..row_len) |row| {
            inline for (0..col_len) |col| {
                const v = b[row];
                out[row][col] = 0;
                inline for (0..col_len) |i| {
                    out[row][col] += a[i][col] * v[i];
                }
            }
        }
        return out;
    }

    pub inline fn transpose(m: anytype) @TypeOf(m) {
        switch (@TypeOf(m)) {
            Mat2, Mat3, Mat4 => {},
            else => unsupportedType(@TypeOf(m)),
        }

        const row_len = veclen(@TypeOf(m[0]));
        const col_len = m.len;

        var out: @TypeOf(m) = undefined;
        inline for (0..row_len) |row| {
            inline for (0..col_len) |col| {
                out[row][col] = m[col][row];
            }
        }
        return out;
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
        return mul(m.*, scaling(s));
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
        const d = far - near;

        return .{
            .{ 1.0 / (aspect * h), 0.0, 0.0, 0.0 },
            .{ 0.0, 1.0 / h, 0.0, 0.0 },
            .{ 0.0, 0.0, -(far + near) / d, -1.0 },
            .{ 0.0, 0.0, -(2.0 * far * near) / d, 0.0 },
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

    pub inline fn determinant(m: anytype) f32 {
        return switch (@TypeOf(m)) {
            Mat2 => m[0][0] * m[1][1] - m[1][0] * m[0][1],
            Mat3 => {
                const cofactor0 = determinant(Mat2{
                    .{ m[1][1], m[2][1] },
                    .{ m[1][2], m[2][2] },
                });
                const cofactor1 = determinant(Mat2{
                    .{ m[0][1], m[2][1] },
                    .{ m[0][2], m[2][2] },
                });
                const cofactor2 = determinant(Mat2{
                    .{ m[0][1], m[1][1] },
                    .{ m[0][2], m[1][2] },
                });

                return m[0][0] * cofactor0 - m[1][0] * cofactor1 + m[2][0] * cofactor2;
            },
            Mat4 => {
                const cofactor0 = determinant(Mat3{
                    .{ m[1][1], m[2][1], m[3][1] },
                    .{ m[1][2], m[2][2], m[3][2] },
                    .{ m[1][3], m[2][3], m[3][3] },
                });
                const cofactor1 = determinant(Mat3{
                    .{ m[0][1], m[2][1], m[3][1] },
                    .{ m[0][2], m[2][2], m[3][2] },
                    .{ m[0][3], m[2][3], m[3][3] },
                });
                const cofactor2 = determinant(Mat3{
                    .{ m[0][1], m[1][1], m[3][1] },
                    .{ m[0][2], m[1][2], m[3][2] },
                    .{ m[0][3], m[1][3], m[3][3] },
                });
                const cofactor3 = determinant(Mat3{
                    .{ m[0][1], m[1][1], m[2][1] },
                    .{ m[0][2], m[1][2], m[2][2] },
                    .{ m[0][3], m[1][3], m[2][3] },
                });

                return m[0][0] * cofactor0 -
                    m[1][0] * cofactor1 +
                    m[2][0] * cofactor2 -
                    m[3][0] * cofactor3;
            },
            else => unsupportedType(@TypeOf(m)),
        };
    }
};

// pub const Sphere = struct {
//     const Self = @This();

//     center: Vec3,
//     radius: f32,

//     pub fn contains(self: Self, point: Vec3) bool {
//         return vec.distance(self.center, point) <= self.radius;
//     }

//     pub fn createCircumsphere(a: Vec3, b: Vec3, c: Vec3, d: Vec3) Self {
//         const a2 = vec.length2(a);
//         _ = a2;
//         const b2 = vec.length2(b);
//         _ = b2;
//         const c2 = vec.length2(c);
//         _ = c2;
//         const d2 = vec.length2(d);
//         _ = d2;
//     }
// };

// pub fn smallestEnclosingSphere(points: []Vec3) Sphere {
//     _ = points;
// }
