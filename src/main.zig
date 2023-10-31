const std = @import("std");
const glfw = @import("glfw");
const builtin = @import("builtin");
const c = @import("c.zig");

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stderr = std.io.getStdErr().writer();

    const args = try std.process.argsAlloc(allocator);
    if (args.len != 2) {
        try std.fmt.format(stderr, "usage: {s} <obj_file>\n", .{args[0]});
        return 1;
    }

    if (!std.mem.endsWith(u8, args[1], ".obj")) {
        try std.fmt.format(stderr, "only supports wavefront OBJ files (.obj)\n", .{});
        return 1;
    }

    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        return 1;
    }
    defer glfw.terminate();

    glfw.setErrorCallback(errorCallback);

    const window_hints = glfw.Window.Hints{
        .context_version_major = 4,
        .context_version_minor = 1,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = if (builtin.os.tag == .macos) true else false,
        .samples = 4,
    };
    const window = glfw.Window.create(800, 600, "scop", null, null, window_hints) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        return 1;
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);

    if (c.gladLoadGLLoader(@ptrCast(&glfw.getProcAddress)) == 0) return 1;

    c.glEnable(c.GL_MULTISAMPLE);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_STENCIL_TEST);
    c.glEnable(c.GL_CULL_FACE);

    while (!window.shouldClose()) {
        c.glClearColor(0.1, 0.1, 0.1, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);
        c.glStencilOp(c.GL_KEEP, c.GL_KEEP, c.GL_REPLACE);
        c.glStencilFunc(c.GL_ALWAYS, 1, 0xFF);
        c.glStencilMask(0xFF);

        window.swapBuffers();
        glfw.pollEvents();
    }

    return 0;
}
