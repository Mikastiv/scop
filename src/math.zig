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

    inline fn calculateRow(
        a0: anytype,
        a1: @TypeOf(a0),
        a2: @TypeOf(a0),
        a3: @TypeOf(a0),
        b: @TypeOf(a0),
    ) @TypeOf(a0) {
        const part1 = vec.add(vec.mul(a0, b[0]), vec.mul(a1, b[1]));
        const part2 = vec.add(vec.mul(a2, b[2]), vec.mul(a3, b[3]));
        return vec.add(part1, part2);
    }

    pub inline fn mul(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
        return switch (@TypeOf(a)) {
            Mat2 => .{
                .{ a[0][0] * b[0][0] + a[0][1] * b[1][0], a[0][0] * b[0][1] + a[0][1] * b[1][1] },
                .{ a[1][0] * b[0][0] + a[1][1] * b[1][0], a[1][0] * b[0][1] + a[1][1] * b[1][1] },
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
                const a0 = a[0];
                const a1 = a[1];
                const a2 = a[2];
                const a3 = a[3];

                const b0 = b[0];
                const b1 = b[1];
                const b2 = b[2];
                const b3 = b[3];

                break :blk .{
                    calculateRow(a0, a1, a2, a3, b0),
                    calculateRow(a0, a1, a2, a3, b1),
                    calculateRow(a0, a1, a2, a3, b2),
                    calculateRow(a0, a1, a2, a3, b3),
                };
            },
            else => unsupportedType(@TypeOf(a)),
        };
    }
};
