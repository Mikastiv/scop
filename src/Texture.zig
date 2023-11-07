const Self = @This();
const c = @import("c.zig");
const Image = @import("Image.zig");

id: c.GLuint,

pub fn init(image: Image) Self {
    var id: c.GLuint = undefined;
    c.glGenTextures(1, &id);
    c.glBindTexture(c.GL_TEXTURE_2D, id);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_RGB,
        @intCast(image.width),
        @intCast(image.height),
        0,
        c.GL_RGBA,
        c.GL_UNSIGNED_BYTE,
        @ptrCast(image.pixels.ptr),
    );
    c.glGenerateMipmap(c.GL_TEXTURE_2D);

    return .{ .id = id };
}

pub fn bind(self: Self, slot: c.GLenum) void {
    c.glActiveTexture(slot);
    c.glBindTexture(c.GL_TEXTURE_2D, self.id);
}
