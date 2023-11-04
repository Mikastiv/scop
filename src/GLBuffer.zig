const Self = @This();
const c = @import("c.zig");

id: c.GLuint,
gl_type: c.GLenum,

pub const invalid_buffer = Self{ .id = c.GL_INVALID_VALUE, .gl_type = c.GL_INVALID_ENUM };

pub fn init(comptime T: type, gl_type: c.GLenum, data: []T) Self {
    var id: c.GLuint = undefined;
    c.glGenBuffers(1, @ptrCast(&id));
    c.glBindBuffer(gl_type, id);
    c.glBufferData(
        gl_type,
        @intCast(@sizeOf(T) * data.len),
        data.ptr,
        c.GL_STATIC_DRAW,
    );

    return .{ .id = id, .gl_type = gl_type };
}

pub fn bind(self: Self) void {
    c.glBindBuffer(self.gl_type, self.id);
}

pub fn unbind(self: Self) void {
    c.glBindBuffer(self.gl_type, 0);
}

pub fn deinit(self: Self) void {
    c.glDeleteBuffers(1, @ptrCast(&self.id));
}
