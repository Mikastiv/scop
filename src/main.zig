const std = @import("std");
const glfw = @import("glfw");
const builtin = @import("builtin");
const c = @import("c.zig");
const Shader = @import("shader.zig").Shader;
const math = @import("math.zig");
const obj = @import("obj.zig");

var window_width: u32 = 800;
var window_height: u32 = 600;
var aspect_ratio: f32 = 800.0 / 600.0;

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn framebufferSizeCallback(_: glfw.Window, width: u32, height: u32) void {
    window_width = width;
    window_height = height;
    aspect_ratio = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    c.glViewport(0, 0, @intCast(width), @intCast(height));
}

fn keyboardCallback(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
    if (key == glfw.Key.escape and action == glfw.Action.press) window.setShouldClose(true);
    _ = mods;
    _ = scancode;
}

fn mouseCallback(window: glfw.Window, xpos: f64, ypos: f64) void {
    _ = ypos;
    _ = xpos;
    _ = window;
}

fn scrollCallback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
    _ = yoffset;
    _ = xoffset;
    _ = window;
}

fn validateArgs(args: []const []const u8) !bool {
    const stderr = std.io.getStdErr().writer();

    if (args.len != 2) {
        try stderr.print("usage: {s} <obj_file>\n", .{args[0]});
        return false;
    }

    if (!std.mem.endsWith(u8, args[1], ".obj")) {
        std.log.err("only supports wavefront OBJ files (.obj)\n", .{});
        return false;
    }

    return true;
}

fn createWindow() !glfw.Window {
    const window_hints = glfw.Window.Hints{
        .context_version_major = 4,
        .context_version_minor = 1,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = if (builtin.os.tag == .macos) true else false,
        .samples = 4,
    };
    const window = glfw.Window.create(window_width, window_height, "scop", null, null, window_hints) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        return error.GlfwWindowCreationFailed;
    };

    glfw.makeContextCurrent(window);
    window.setFramebufferSizeCallback(framebufferSizeCallback);
    window.setKeyCallback(keyboardCallback);
    window.setCursorPosCallback(mouseCallback);
    window.setScrollCallback(scrollCallback);

    if (c.gladLoadGLLoader(@ptrCast(&glfw.getProcAddress)) == 0) return error.GLLoaderFailed;

    return window;
}

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    if (!try validateArgs(args)) return 1;

    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        return error.GlfwInitFailed;
    }
    defer glfw.terminate();

    glfw.setErrorCallback(errorCallback);

    const window = try createWindow();
    defer window.destroy();

    const s = try Shader.init(allocator, "shaders/pbr.vert", "shaders/pbr.frag");
    defer s.deinit();

    var model = try obj.parseObj(allocator, args[1]);
    model.loadOnGpu();

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
