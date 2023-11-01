const std = @import("std");

pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);
pub const Vec4 = @Vector(4, f32);

pub const vec2 = struct {
    pub fn init(x: f32, y: f32) Vec2 {
        return .{ x, y };
    }

    pub fn length(v: Vec2) f32 {
        return @sqrt(v[0] * v[0] + v[1] * v[1]);
    }

    pub fn unit(v: Vec2) Vec2 {
        const len = v.length();
        return .{v / len};
    }

    pub fn normalize(v: Vec2) Vec2 {
        return v.unit();
    }

    pub fn dot(a: Vec2, b: Vec2) f32 {
        return a[0] * b[0] + a[1] * b[1];
    }
};

pub const vec3 = struct {
    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ x, y, z };
    }

    pub fn length(v: Vec3) f32 {
        return @sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    }

    pub fn unit(v: Vec3) Vec3 {
        const len = v.length();
        return .{v / len};
    }

    pub fn normalize(v: Vec3) Vec3 {
        return v.unit();
    }

    pub fn dot(a: Vec3, b: Vec3) f32 {
        return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    }

    pub fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{
            a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0],
        };
    }
};

pub const vec4 = struct {
    pub fn init(x: f32, y: f32, z: f32, w: f32) Vec4 {
        return .{ x, y, z, w };
    }

    pub fn length(v: Vec4) f32 {
        return @sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2] + v[3] * v[3]);
    }

    pub fn unit(v: Vec4) Vec4 {
        const len = v.length();
        return .{v / len};
    }

    pub fn normalize(v: Vec4) Vec4 {
        return v.unit();
    }

    pub fn dot(a: Vec4, b: Vec4) f32 {
        return a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
    }
};
