const Self = @This();
const std = @import("std");
const math = @import("math.zig");

speed: f32,
pitch: f32,
yaw: f32,
pos: math.Vec3,
up: math.Vec3,
right: math.Vec3,
direction: math.Vec3,

pub fn init(pos: math.Vec3, up: math.Vec3, speed: f32) Self {
    var self = Self{
        .speed = speed,
        .pitch = 0,
        .yaw = -90,
        .pos = pos,
        .up = math.vec.normalize(up),
        .right = .{ 0, 0, 0 },
        .direction = .{ 0, 0, 0 },
    };
    self.updateDirection(.{ 0, 0 });

    return self;
}

pub fn updateDirection(self: *Self, offset: math.Vec2) void {
    self.yaw += offset[0];
    self.pitch += offset[1];

    if (self.pitch > 89) self.pitch = 89;
    if (self.pitch < -89) self.pitch = -89;

    const yaw = std.math.degreesToRadians(f32, self.yaw);
    const pitch = std.math.degreesToRadians(f32, self.pitch);

    const direction = math.Vec3{
        @cos(yaw) * @cos(pitch),
        @sin(pitch),
        @sin(yaw) * @cos(pitch),
    };

    self.direction = math.vec.normalize(direction);
    self.right = math.vec.normalize(math.vec.cross(self.direction, self.up));
}

pub fn viewMatrix(self: *const Self) math.Mat4 {
    const pos_dir = math.vec.add(self.pos, self.direction);
    return math.mat.lookAt(self.pos, pos_dir, self.up);
}
