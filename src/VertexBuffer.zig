const Self = @This();
const c = @import("c.zig");

id: c.GLuint,

pub fn init(comptime T: type, data: []T) Self {
    var vbo: c.GLuint = undefined;
    c.glGenBuffers(1, @ptrCast(&vbo));
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @intCast(@sizeOf(T) * data.len),
        data.ptr,
        c.GL_STATIC_DRAW,
    );
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    return .{ .id = vbo };
}

pub fn deinit(self: Self) void {
    c.glDeleteBuffers(1, @ptrCast(&self.id));
}
