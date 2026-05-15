const std = @import("std");
const glfw = @import("zglfw");
const zgl = @import("zopengl");
const gl = zgl.bindings;
const wrap = zgl.wrappers;
const Vao = @import("graphics/opengl/vertex_array.zig").VertexArray;
const Shader = @import("graphics/opengl/shader.zig").Shader;

pub fn run(init: std.process.Init) !void {
    _ = init;

    const width: c_int = 600;
    const height: c_int = 600;

    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.context_version_major, 4);
    glfw.windowHint(.context_version_minor, 0);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);

    const window = try glfw.Window.create(width, height, "Engine", null, null);
    defer window.destroy();

    glfw.makeContextCurrent(window);
    try zgl.loadCoreProfile(glfw.getProcAddress, 4, 0);

    gl.viewport(0, 0, width, height);
    _ = glfw.setFramebufferSizeCallback(window, window_resize_callback);

    // --- 1. SHADER SETUP ---
    const v_code = @embedFile("vertex.glsl");
    const f_code = @embedFile("frag.glsl");

    // Pass the embedded files directly as slices
    const shader_program = Shader.init(v_code, f_code);
    defer shader_program.deleteProgram();
    shader_program.deleteVertexShader();
    shader_program.deleteFragmentShader();

    // --- 2. VERTEX DATA ---
    const vertices = [_]f32{
        // positions        // colors
        0.5,  0.5,  0.0, 0.05, 0.34,  0.8,
        0.5,  -0.5, 0.0, 0.63, 0.5,   0.0,
        -0.5, -0.5, 0.0, 0.01, 0.501, 0.07,
        -0.5, 0.5,  0.0, 0.48, 0.011, 0.501,
    };

    const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

    const vao = Vao.init(&vertices, &indices);
    defer vao.deinit();

    vao.AddAttribPointer(0, 3, 6 * @sizeOf(f32), null);
    const color_offset: usize = 3 * @sizeOf(f32);
    vao.AddAttribPointer(1, 3, 6 * @sizeOf(f32), @ptrFromInt(color_offset));

    vao.unbind();

    const useUniformColor = true;

    // --- 3. MAIN RENDER LOOP ---
    while (!window.shouldClose()) {
        process_inputs(window);

        gl.clearColor(0.1, 0.2, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        shader_program.useProgram();

        const time: f32 = @floatCast(glfw.getTime());
        const red_value: f32 = (std.math.sin(time) / 1.0) + 0.5;
        const green_value: f32 = (std.math.sin(time) / 2.0) + 0.5;
        const blue_value: f32 = (std.math.sin(time) / 3.0) + 0.5;

        shader_program.setBool("useUniformColor", useUniformColor);
        shader_program.setFloatVec4("colorFromUniform", red_value, green_value, blue_value, 1.0);

        vao.bind();
        gl.drawElements(gl.TRIANGLES, indices.len, gl.UNSIGNED_INT, null);

        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn window_resize_callback(_: *glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    gl.viewport(0, 0, width, height);
}

fn process_inputs(window: *glfw.Window) callconv(.c) void {
    if (glfw.getKey(window, glfw.Key.escape) == glfw.Action.press) {
        window.setShouldClose(true);
    }
}
