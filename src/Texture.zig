const Self = @This();
const c = @import("c.zig");
const Image = @import("Image.zig");

id: c.GLuint = c.GL_INVALID_VALUE,
image: Image,

pub fn loadOnGpu(self: *Self) void {
    c.glGenTextures(1, &self.id);
    c.glBindTexture(c.GL_TEXTURE_2D, self.id);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_RGB,
        @intCast(self.image.width),
        @intCast(self.image.height),
        0,
        c.GL_RGBA,
        c.GL_UNSIGNED_BYTE,
        @ptrCast(self.image.pixels.ptr),
    );
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
}

pub fn bind(self: Self, slot: c.GLenum) void {
    c.glActiveTexture(slot);
    c.glBindTexture(c.GL_TEXTURE_2D, self.id);
}
