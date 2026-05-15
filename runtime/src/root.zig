const std = @import("std");
const glfw = @import("zglfw");
const zgl = @import("zopengl");
const gl = zgl.bindings;

const VertexArray = @import("graphics/opengl/vertex_array.zig").VertexArray;
const Shader = @import("graphics/opengl/shader.zig").Shader;
const windowFile = @import("graphics/window.zig");
const Window = windowFile.Window;
const WindowConfig = windowFile.WindowConfig;

pub fn run(allocator: std.mem.Allocator) !void {
    const config = WindowConfig{
        .width = 600,
        .height = 600,
        .title = "Engine",
        .api = .opengl,
    };

    const window = try Window.init(allocator, config);
    defer window.deinit(allocator);

    if (window.api == .opengl) {
        try zgl.loadCoreProfile(glfw.getProcAddress, 4, 0);
    }

    const shader_program = Shader.init(@embedFile("vertex.glsl"), @embedFile("frag.glsl"));
    defer shader_program.deleteProgram();

    const vertices = [_]f32{
        0.5,  0.5,  0.0, 0.05, 0.34, 0.8,
        0.5,  -0.5, 0.0, 0.63, 0.5,  0.0,
        -0.5, -0.5, 0.0, 0.01, 0.50, 0.07,
        -0.5, 0.5,  0.0, 0.48, 0.01, 0.50,
    };
    const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

    const vertex_array = VertexArray.init(&vertices, &indices);
    defer vertex_array.deinit();
    vertex_array.AddAttribPointer(0, 3, 6 * @sizeOf(f32), null);
    vertex_array.AddAttribPointer(1, 3, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));

    const useUniformColor = true;

    while (!window.shouldClose()) {
        // 1. Collect raw events from OS
        window.pollEvents();

        // 2. Process our abstracted event queue
        while (window.nextEvent()) |event| {
            switch (event) {
                .key_press => |e| {
                    if (e.key == .escape) window.handle.setShouldClose(true);
                },
                .window_resize => |e| {
                    gl.viewport(0, 0, e.width, e.height);
                },
                else => {},
            }
        }

        // 3. Real-time Polling (for smooth movement)
        if (window.isKeyDown(.w)) {
            // e.g. camera.moveForward();
        }

        // 4. Rendering
        gl.clearColor(0.1, 0.2, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        shader_program.useProgram();

        const time: f32 = @floatCast(glfw.getTime());
        const red_value: f32 = (std.math.sin(time) / 1.0) + 0.5;
        const green_value: f32 = (std.math.sin(time) / 2.0) + 0.5;
        const blue_value: f32 = (std.math.sin(time) / 3.0) + 0.5;

        shader_program.setBool("useUniformColor", useUniformColor);
        shader_program.setFloatVec4("colorFromUniform", red_value, green_value, blue_value, 1.0);

        vertex_array.bind();
        gl.drawElements(gl.TRIANGLES, indices.len, gl.UNSIGNED_INT, null);

        window.swapBuffers();
    }
}
