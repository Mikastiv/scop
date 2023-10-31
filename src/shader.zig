const std = @import("std");
const c = @import("c.zig");

fn compileShader(shader_bytes: []const u8, shader_type: c.GLenum) error{ShaderCompilationFailed}!c.GLuint {
    var success: c_int = undefined;
    var info_log: [512]u8 = undefined;

    const shader = c.glCreateShader(shader_type);
    c.glShaderSource(shader, 1, @ptrCast(&shader_bytes.ptr), null);
    c.glCompileShader(shader);
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetShaderInfoLog(shader, info_log.len, null, @ptrCast(&info_log));
        std.log.err("opengl: failed to compile shader \"{s}\"\n{s}\n", .{ shader_bytes, info_log });
        return error.ShaderCompilationFailed;
    }

    return shader;
}

pub const Shader = struct {
    const Self = @This();

    id: c.GLuint,

    pub fn init(allocator: std.mem.Allocator, vertex_path: []const u8, fragment_path: []const u8) !Self {
        const vertex_shader = try std.fs.cwd().openFile(vertex_path, .{});
        const fragment_shader = try std.fs.cwd().openFile(fragment_path, .{});
        const vertex_bytes = try vertex_shader.readToEndAllocOptions(allocator, std.math.maxInt(usize), null, 1, 0);
        const fragment_bytes = try fragment_shader.readToEndAllocOptions(allocator, std.math.maxInt(usize), null, 1, 0);

        const vertex = try compileShader(vertex_bytes, c.GL_VERTEX_SHADER);
        defer c.glDeleteShader(vertex);
        const fragment = try compileShader(fragment_bytes, c.GL_FRAGMENT_SHADER);
        defer c.glDeleteShader(fragment);

        const id = c.glCreateProgram();
        c.glAttachShader(id, vertex);
        c.glAttachShader(id, fragment);
        c.glLinkProgram(id);

        var success: c_int = undefined;
        var info_log: [512]u8 = undefined;
        c.glGetProgramiv(id, c.GL_LINK_STATUS, &success);
        if (success == c.GL_FALSE) {
            c.glGetProgramInfoLog(id, info_log.len, null, @ptrCast(&info_log));
            std.log.err("opengl: failed to link shader\n{s}\n", .{info_log});
            return error.ShaderLinkFailed;
        }

        return .{
            .id = 0,
        };
    }

    pub fn deinit(self: Self) void {
        c.glDeleteProgram(self.id);
    }
};
