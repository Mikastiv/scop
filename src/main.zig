const std = @import("std");
const glfw = @import("glfw");
const builtin = @import("builtin");
const c = @import("c.zig");
const Shader = @import("Shader.zig");
const math = @import("math.zig");
const obj = @import("obj.zig");
const UniformBuffer = @import("UniformBuffer.zig");
const shape = @import("shape.zig");
const PointLight = @import("PointLight.zig");
const Camera = @import("Camera.zig");
const bmp = @import("bmp.zig");
const DebugPlane = @import("DebugPlane.zig");
const Texture = @import("Texture.zig");

const default_window_width = 800;
const default_window_height = 600;

var window_width: u32 = default_window_width;
var window_height: u32 = default_window_height;
var aspect_ratio: f32 = @as(f32, default_window_width) / @as(f32, default_window_height);

var camera: Camera = Camera.init(.{ 0, 0, 7 }, .{ 0, 1, 0 }, 9);
var first_mouse = true;
var last_mouse_pos = math.Vec2{ default_window_width / 2.0, default_window_height / 2.0 };
const sensitivity = 0.075;
var fov: f32 = 45.0;

const model_rotation_speed = 2.0;
var model_angles = math.Vec3{ 0, 0, 0 };

var current_mode = DrawMode.triangles;

const DrawMode = enum(u8) {
    triangles,
    pbr,
    count,

    fn nextValue(mode: DrawMode) DrawMode {
        const value = @intFromEnum(mode);
        const next = (value + 1) % @intFromEnum(DrawMode.count);
        return @enumFromInt(next);
    }
};

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn framebufferSizeCallback(_: glfw.Window, width: u32, height: u32) void {
    window_width = width;
    window_height = height;
    aspect_ratio = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    c.glViewport(0, 0, @intCast(width), @intCast(height));
}

fn keyboardCallback(window: glfw.Window, key: glfw.Key, _: i32, action: glfw.Action, _: glfw.Mods) void {
    if (key == .escape and action == .press) window.setShouldClose(true);
    if (key == .q and action == .press) current_mode = DrawMode.nextValue(current_mode);
}

fn mouseCallback(_: glfw.Window, xpos: f64, ypos: f64) void {
    const xpos_f32: f32 = @floatCast(xpos);
    const ypos_f32: f32 = @floatCast(ypos);

    if (first_mouse) {
        first_mouse = false;
        last_mouse_pos[0] = xpos_f32;
        last_mouse_pos[1] = ypos_f32;
    }

    const offset = math.Vec2{
        xpos_f32 - last_mouse_pos[0],
        last_mouse_pos[1] - ypos_f32,
    };

    last_mouse_pos = .{ xpos_f32, ypos_f32 };

    camera.updateDirection(.{ offset[0] * sensitivity, offset[1] * sensitivity });
}

fn scrollCallback(_: glfw.Window, _: f64, yoffset: f64) void {
    fov -= @floatCast(yoffset);
    if (fov < 1.0) fov = 1.0;
    if (fov > 45.0) fov = 45.0;
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

fn adjustAngle(angle: f32) f32 {
    var x = angle;
    if (x > std.math.tau) x -= std.math.tau;
    if (x < 0) x += std.math.tau;
    return x;
}

fn processInput(window: glfw.Window, cam: *Camera, dt: f32) void {
    const speed = cam.speed * dt;
    const d_forward = math.vec.mul(cam.direction, speed);
    const d_right = math.vec.mul(cam.right, speed);
    if (window.getKey(.w) == .press) cam.pos = math.vec.add(cam.pos, d_forward);
    if (window.getKey(.s) == .press) cam.pos = math.vec.sub(cam.pos, d_forward);
    if (window.getKey(.d) == .press) cam.pos = math.vec.add(cam.pos, d_right);
    if (window.getKey(.a) == .press) cam.pos = math.vec.sub(cam.pos, d_right);
    if (window.getKey(.space) == .press) cam.pos[1] += speed;
    if (window.getKey(.left_shift) == .press) cam.pos[1] -= speed;
    if (window.getKey(.r) == .press) model_angles[0] -= model_rotation_speed * dt;
    if (window.getKey(.t) == .press) model_angles[0] += model_rotation_speed * dt;
    if (window.getKey(.f) == .press) model_angles[1] -= model_rotation_speed * dt;
    if (window.getKey(.g) == .press) model_angles[1] += model_rotation_speed * dt;
    if (window.getKey(.v) == .press) model_angles[2] -= model_rotation_speed * dt;
    if (window.getKey(.b) == .press) model_angles[2] += model_rotation_speed * dt;
    model_angles[0] = adjustAngle(model_angles[0]);
    model_angles[1] = adjustAngle(model_angles[1]);
    model_angles[2] = adjustAngle(model_angles[2]);
}

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (!try validateArgs(args)) {
        return 1;
    }

    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        return error.GlfwInitFailed;
    }
    defer glfw.terminate();

    glfw.setErrorCallback(errorCallback);

    const window = try createWindow();
    defer window.destroy();

    window.setInputMode(.cursor, .disabled);

    const shader_pbr = try Shader.init(allocator, "shaders/pbr.vert", "shaders/pbr.frag");
    defer shader_pbr.deinit();
    const shader_light = try Shader.init(allocator, "shaders/light.vert", "shaders/light.frag");
    defer shader_light.deinit();
    const shader_debug = try Shader.init(allocator, "shaders/debug.vert", "shaders/debug.frag");
    defer shader_debug.deinit();
    const shader_tri_colored = try Shader.init(allocator, "shaders/tri_color.vert", "shaders/tri_color.frag");
    defer shader_tri_colored.deinit();

    var model3d = try obj.parseObj(allocator, args[1]);
    try model3d.loadOnGpu();

    const mesh_count = model3d.meshes.items.len;
    var vertex_count: usize = 0;
    var index_count: usize = 0;
    for (model3d.meshes.items) |mesh| {
        vertex_count += mesh.vertices.items.len;
        index_count += mesh.indices.items.len;
    }
    std.log.info("meshes: {d}, vertices: {d}, indices: {d}\n", .{ mesh_count, vertex_count, index_count });

    var debug_plane = try DebugPlane.init(allocator, "res/backpack/diffuse.bmp");
    defer debug_plane.deinit();

    c.glEnable(c.GL_MULTISAMPLE);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_CULL_FACE);

    var sphere = try shape.generateSphere(allocator, 64, 64);
    defer sphere.deinit();
    sphere.loadOnGpu();

    const matrices_uniform = UniformBuffer.init(2 * @sizeOf(math.Mat4));
    defer matrices_uniform.deinit();

    matrices_uniform.bindRange(0);
    shader_pbr.setUniformBlock("matrices", 0);
    shader_light.setUniformBlock("matrices", 0);
    shader_tri_colored.setUniformBlock("matrices", 0);

    const light_color = math.Vec3{ 300, 300, 300 };
    const lights = [_]PointLight{
        .{ .pos = .{ -5, 5, 5 }, .color = light_color },
        .{ .pos = .{ 5, 5, 5 }, .color = light_color },
        .{ .pos = .{ -5, -5, 5 }, .color = light_color },
        .{ .pos = .{ 5, -5, 5 }, .color = light_color },
    };

    var last_frame: f64 = 0;
    while (!window.shouldClose()) {
        const now = glfw.getTime();
        const delta_time = @as(f32, @floatCast(now - last_frame));
        last_frame = glfw.getTime();

        processInput(window, &camera, delta_time);

        c.glClearColor(0.1, 0.1, 0.1, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        const view = camera.viewMatrix();
        const projection = math.mat.perspective(
            std.math.degreesToRadians(f32, fov),
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
            model = math.mat.translate(&model, l.pos);
            model = math.mat.scaleScalar(&model, 0.3);
            shader_light.setUniform(math.Mat4, "model", model);
            sphere.draw(shader_light);
        }

        var model = math.mat.identity(math.Mat4);
        model = math.mat.scaleScalar(&model, 0.75);
        model = math.mat.rotate(&model, model_angles[0], .{ 1, 0, 0 });
        model = math.mat.rotate(&model, model_angles[1], .{ 0, 1, 0 });
        model = math.mat.rotate(&model, model_angles[2], .{ 0, 0, 1 });

        switch (current_mode) {
            .triangles => {
                shader_tri_colored.use();
                shader_tri_colored.setUniform(math.Mat4, "model", model);
                model3d.draw(shader_tri_colored);
            },
            .pbr => {
                shader_pbr.use();
                for (lights, 0..) |l, i| {
                    var buffer: [256]u8 = undefined;
                    var slice = try std.fmt.bufPrintZ(&buffer, "light_positions[{d}]", .{i});
                    shader_pbr.setUniform(math.Vec3, slice, l.pos);
                    slice = try std.fmt.bufPrintZ(&buffer, "light_colors[{d}]", .{i});
                    shader_pbr.setUniform(math.Vec3, slice, l.color);
                }

                shader_pbr.setUniform(math.Vec3, "camera_position", camera.pos);
                shader_pbr.setUniform(math.Mat4, "model", model);
                // transpose, inverse
                model3d.draw(shader_pbr);
            },
            else => unreachable,
        }

        // debug_plane.draw();

        window.swapBuffers();
        glfw.pollEvents();
    }

    return 0;
}
