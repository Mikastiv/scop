const Self = @This();
const c = @import("c.zig");
const Mat4 = @import("math.zig").Mat4;

id: c.GLuint,
size: c.GLsizeiptr,

pub fn init(size: c.GLsizeiptr) Self {
    var ubo: c.GLuint = undefined;
    c.glGenBuffers(1, @ptrCast(&ubo));
    c.glBindBuffer(c.GL_UNIFORM_BUFFER, ubo);
    c.glBufferData(c.GL_UNIFORM_BUFFER, size, null, c.GL_STATIC_DRAW);
    c.glBindBuffer(c.GL_UNIFORM_BUFFER, 0);

    return .{ .id = ubo, .size = size };
}

pub fn bindRange(self: Self, binding_point: c.GLuint) void {
    c.glBindBuffer(c.GL_UNIFORM_BUFFER, self.ubo);
    c.glBindBufferRange(c.GL_UNIFORM_BUFFER, binding_point, self.ubo, 0, self.size);
    c.glBindBuffer(c.GL_UNIFORM_BUFFER, 0);
}

pub fn deinit(self: Self) void {
    c.glDeleteBuffers(1, @ptrCast(&self.id));
}
