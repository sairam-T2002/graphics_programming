const std = @import("std");
const glfw = @import("zglfw");
const zgl = @import("zopengl");
const gl = zgl.bindings;
const zstbi = @import("zstbi");
const zlm = @import("zlm").as(f32);
const ITexture = @import("graphics/interfaces/Itexture.zig").ITexture;

const VertexArray = @import("graphics/opengl/vertex_array.zig").VertexArray;
const Shader = @import("graphics/opengl/shader.zig").Shader;
const windowFile = @import("core/window.zig");
const Window = windowFile.Window;
const WindowConfig = windowFile.WindowConfig;

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
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

    const shader_program = Shader.init(@embedFile("graphics/opengl/shaders/vert.glsl"), @embedFile("graphics/opengl/shaders/frag.glsl"));
    defer shader_program.deleteProgram();

    const vertices = [_]f32{
        // positions      // colors          // UV
        -0.5, 0.5,  0.0, 0.05, 0.34, 0.8,  0.0, 1.0,
        -0.5, -0.5, 0.0, 0.63, 0.5,  0.0,  0.0, 0.0,
        0.5,  -0.5, 0.0, 0.01, 0.50, 0.07, 1.0, 0.0,
        0.5,  0.5,  0.0, 0.48, 0.01, 0.50, 1.0, 1.0,
    };
    const indices = [_]u32{
        0, 1, 2,
        0, 2, 3,
    };

    zstbi.init(io, allocator);
    defer zstbi.deinit();
    zstbi.setFlipVerticallyOnLoad(true);

    const vertex_array = VertexArray.init(&vertices, &indices);
    defer vertex_array.deinit();
    vertex_array.AddAttribPointer(0, 3, 8 * @sizeOf(f32), null);
    vertex_array.AddAttribPointer(1, 3, 8 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    vertex_array.AddAttribPointer(2, 2, 8 * @sizeOf(f32), @ptrFromInt(6 * @sizeOf(f32)));

    // Initialize Textures
    const wall_texture = try ITexture.init(window.api, "wall.jpg", .{
        .filter = .nearest,
        .wrap = .repeat,
        .generate_mipmaps = false,
    });
    defer wall_texture.deinit();

    const smiley_texture = try ITexture.init(window.api, "smiley.jpg", .{
        .filter = .nearest,
        .wrap = .repeat,
        .generate_mipmaps = false,
    });
    defer smiley_texture.deinit();

    // Map Samplers to Texture Units
    shader_program.useProgram();
    shader_program.setInt("textureFromProgram1", 0);
    shader_program.setInt("textureFromProgram2", 1);

    var rotation: zlm.Mat4 = undefined;
    const scaling: zlm.Mat4 = zlm.Mat4.createScale(0.5, 0.5, 0.5);
    var trans: zlm.Mat4 = undefined;

    const useUniformColor = true;
    const useUniformTexture = true;

    while (!window.shouldClose()) {
        window.pollEvents();
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

        gl.clearColor(0.1, 0.2, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        shader_program.useProgram();

        // Bind each texture to its assigned unit
        wall_texture.bind(0);
        smiley_texture.bind(1);

        const time: f32 = @floatCast(glfw.getTime());
        const red_value: f32 = (std.math.sin(time) / 1.0) + 0.5;
        const green_value: f32 = (std.math.sin(time) / 2.0) + 0.5;
        const blue_value: f32 = (std.math.sin(time) / 3.0) + 0.5;

        // rotation
        rotation = zlm.Mat4.createAngleAxis(zlm.Vec3.new(0.0, 0.0, 1.0), time);
        trans = rotation.mul(scaling);
        shader_program.setMat4("transform", trans, gl.FALSE);

        shader_program.setBool("useUniformColor", useUniformColor);
        shader_program.setBool("useUniformTexture", useUniformTexture);
        shader_program.setFloatVec4("colorFromUniform", red_value, green_value, blue_value, 1.0);

        vertex_array.bind();
        gl.drawElements(gl.TRIANGLES, indices.len, gl.UNSIGNED_INT, null);

        window.swapBuffers();
    }
}
