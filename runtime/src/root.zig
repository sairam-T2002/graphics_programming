const std = @import("std");
const glfw = @import("zglfw");
const zgl = @import("zopengl");
const gl = zgl.bindings;
const wrap = zgl.wrappers;

pub fn run(init: std.process.Init) !void {
    _ = init;

    const width: c_int = 600;
    const height: c_int = 600;

    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.context_version_major, 4);
    glfw.windowHint(.context_version_minor, 0);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);

    const window = try glfw.Window.create(width, height, "Zig Triangle", null, null);
    defer window.destroy();

    glfw.makeContextCurrent(window);
    try zgl.loadCoreProfile(glfw.getProcAddress, 4, 0);

    gl.viewport(0, 0, width, height);
    _ = glfw.setFramebufferSizeCallback(window, window_resize_callback);

    // --- 1. SHADER SETUP ---

    // VERTEX SHADER: Processes raw coordinates
    const vertex_shader = gl.createShader(gl.VERTEX_SHADER);
    const v_code = @embedFile("vertex.glsl");
    const v_ptr: ?[*]const u8 = v_code.ptr;
    gl.shaderSource(vertex_shader, 1, @ptrCast(&v_ptr), null);
    gl.compileShader(vertex_shader);

    // Vertex Shader Check
    var success: i32 = undefined;
    var info_log: [512]u8 = undefined;
    gl.getShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vertex_shader, 512, null, &info_log);
        std.debug.print("Vertex Shader Error: {s}\n", .{info_log[0..]});
    }

    // FRAGMENT SHADER: Determines the color of pixels
    const fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
    const f_code = @embedFile("frag.glsl");
    const f_ptr: ?[*]const u8 = f_code.ptr;
    gl.shaderSource(fragment_shader, 1, @ptrCast(&f_ptr), null);
    gl.compileShader(fragment_shader);

    // Fragment Shader Check
    gl.getShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(fragment_shader, 512, null, &info_log);
        std.debug.print("Fragment Shader Error: {s}\n", .{info_log[0..]});
    }

    // SHADER PROGRAM: Links both shaders into a usable pipeline
    const shader_program = gl.createProgram();
    gl.attachShader(shader_program, vertex_shader);
    gl.attachShader(shader_program, fragment_shader);
    gl.linkProgram(shader_program);
    defer gl.deleteProgram(shader_program);

    // Program Linking Check
    gl.getProgramiv(shader_program, gl.LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(shader_program, 512, null, &info_log);
        std.debug.print("Shader Program Link Error: {s}\n", .{info_log[0..]});
    }

    // Clean up individual shaders as they are now linked into the program
    gl.deleteShader(vertex_shader);
    gl.deleteShader(fragment_shader);

    // --- 2. VERTEX DATA & MEMORY MANAGEMENT ---

    const vertices = [_]f32{
        0.5,  0.5,  0.0,
        0.5,  -0.5, 0.0,
        -0.5, -0.5, 0.0,
        -0.5, 0.5,  0.0,
    };

    const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

    var vao: u32 = undefined;
    var vbo: u32 = undefined;
    var ebo: u32 = undefined;

    // VAO (Vertex Array Object): Acts as a container that stores the "layout"
    // of our data so we don't have to repeat setup inside the render loop.
    gl.genVertexArrays(1, &vao);
    gl.bindVertexArray(vao);
    defer gl.deleteVertexArrays(1, &vao);

    // VBO (Vertex Buffer Object): A buffer in GPU VRAM to store the actual numbers.
    gl.genBuffers(1, &vbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    defer gl.deleteBuffers(1, &vbo);
    // Copying vertices from RAM (Zig array) to VRAM (GPU)
    gl.bufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, gl.STATIC_DRAW);

    // EBO (Element Buffer Object): A buffer in GPU VRAM to store the indices.
    gl.genBuffers(1, &ebo);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    defer gl.deleteBuffers(1, &ebo);
    // Copying indices from RAM (Zig array) to VRAM (GPU)
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), &indices, gl.STATIC_DRAW);

    // Define Attribute 0: Tells the GPU that "location 0" in the shader
    // consists of 3 floats, starting at the beginning (null offset).
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    // Safety: Unbind VAO first so we don't accidentally modify it later.
    gl.bindVertexArray(0);

    var nAttributes: c_int = undefined;
    gl.getIntegerv(gl.MAX_VERTEX_ATTRIBS, &nAttributes);
    std.debug.print("maximum vertex attributes allowed in vertex shader: {d}\n", .{nAttributes});

    // --- 3. MAIN RENDER LOOP ---
    while (!window.shouldClose()) {
        process_inputs(window);

        // Clear the screen with a nice dark blue
        gl.clearColor(0.1, 0.2, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // Use our program and bind the specific vertex data "state" we saved earlier
        gl.useProgram(shader_program);
        gl.bindVertexArray(vao);
        // gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);
        gl.drawElements(gl.TRIANGLES, indices.len, gl.UNSIGNED_INT, null);

        glfw.pollEvents();
        window.swapBuffers();
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
