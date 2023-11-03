const Self = @This();
const c = @import("c.zig");
const Vertex = @import("Vertex.zig");

id: c.GLuint,

pub fn init(comptime T: type, data: []T) Self {
    var id: c.GLuint = undefined;
    c.glGenBuffers(1, @ptrCast(&id));
    c.glBindBuffer(c.GL_ARRAY_BUFFER, id);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @intCast(data.len * @sizeOf(Vertex)),
        data.ptr,
        c.GL_STATIC_DRAW,
    );
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
}

pub fn deinit(self: Self) void {
    c.glDeleteBuffers(1, self.id);
}
