const std = @import("std");
const glfw = @import("glfw");
const builtin = @import("builtin");
const c = @import("c.zig");
const Shader = @import("Shader.zig");
const math = @import("math.zig");
const obj = @import("obj.zig");
const UniformBuffer = @import("UniformBuffer.zig");
const ico = @import("icosphere.zig");
const PointLight = @import("PointLight.zig");

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

    const shader_pbr = try Shader.init(allocator, "shaders/pbr.vert", "shaders/pbr.frag");
    defer shader_pbr.deinit();
    const shader_light = try Shader.init(allocator, "shaders/light.vert", "shaders/light.frag");
    defer shader_light.deinit();

    var model3d = try obj.parseObj(allocator, args[1]);
    model3d.loadOnGpu();

    c.glEnable(c.GL_MULTISAMPLE);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_STENCIL_TEST);
    c.glEnable(c.GL_CULL_FACE);

    // Debug triangle
    const triangle = [_]math.Vec3{
        .{ -0.5, -0.5, 0.0 },
        .{ 0.5, -0.5, 0.0 },
        .{ 0.0, 0.5, 0.0 },
    };
    var vao: u32 = undefined;
    var vbo: u32 = undefined;
    c.glGenVertexArrays(1, @ptrCast(&vao));
    c.glBindVertexArray(vao);
    c.glGenBuffers(1, @ptrCast(&vbo));
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @intCast(@sizeOf(math.Vec3) * 3),
        &triangle,
        c.GL_STATIC_DRAW,
    );
    c.glEnableVertexAttribArray(0);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(math.Vec3), @ptrFromInt(0));
    c.glBindVertexArray(0);

    var sphere = try ico.generateIcosphere(allocator, 3);
    defer sphere.deinit();
    sphere.loadOnGpu();

    const matrices_uniform = UniformBuffer.init(2 * @sizeOf(math.Mat4));
    defer matrices_uniform.deinit();

    matrices_uniform.bindRange(0);
    shader_pbr.setUniformBlock("matrices", 0);
    shader_light.setUniformBlock("matrices", 0);

    const lights = [_]PointLight{
        .{ .pos = .{ 2, 2, 2 } },
        .{ .pos = .{ -2, 2, 2 } },
    };

    var last_frame = glfw.getTime();
    while (!window.shouldClose()) {
        const now = glfw.getTime();
        const delta_time = now - last_frame;
        _ = delta_time;
        last_frame = glfw.getTime();

        c.glClearColor(0.1, 0.1, 0.1, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);
        c.glStencilOp(c.GL_KEEP, c.GL_KEEP, c.GL_REPLACE);
        c.glStencilFunc(c.GL_ALWAYS, 1, 0xFF);
        c.glStencilMask(0xFF);

        const view = math.mat.lookAt(.{ 0, 0, 5 }, .{ 0, 0, 0 }, .{ 0, 1, 0 });
        const projection = math.mat.perspective(
            std.math.degreesToRadians(f32, 45),
            aspect_ratio,
            0.1,
            100.0,
        );

        c.glBindBuffer(c.GL_UNIFORM_BUFFER, matrices_uniform.id);
        c.glBufferSubData(c.GL_UNIFORM_BUFFER, 0, @sizeOf(math.Mat4), @ptrCast(&view));
        c.glBufferSubData(c.GL_UNIFORM_BUFFER, @sizeOf(math.Mat4), @sizeOf(math.Mat4), @ptrCast(&projection));
        c.glBindBuffer(c.GL_UNIFORM_BUFFER, 0);

        shader_light.use();
        for (lights) |l| {
            var model = math.mat.identity(math.Mat4);
            model = math.mat.rotate(&model, std.math.degreesToRadians(f32, 90), .{ 0, 0, 1 });
            model = math.mat.scaleScalar(&model, 0.3);
            model = math.mat.translate(&model, l.pos);
            shader_light.setUniform(math.Mat4, "model", model);
            sphere.draw();
        }

        shader_pbr.use();
        var model = math.mat.identity(math.Mat4);
        model = math.mat.rotate(&model, std.math.degreesToRadians(f32, 90), .{ 0, 0, 1 });
        shader_pbr.setUniform(math.Mat4, "model", model);
        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        c.glBindVertexArray(0);

        window.swapBuffers();
        glfw.pollEvents();
    }

    return 0;
}
