const std = @import("std");
const zstbi = @import("zstbi");
const zlm = @import("zlm").as(f32);

// High-level Agnostic Graphics Abstractions
const Mesh = @import("graphics/mesh.zig").Mesh;
const VertexAttribute = @import("graphics/mesh.zig").VertexAttribute;
const Material = @import("graphics/material.zig").Material;
const IRenderer = @import("graphics/interfaces/Irenderer.zig").IRenderer;
const ITexture = @import("graphics/interfaces/Itexture.zig").ITexture;

const windowFile = @import("core/window.zig");
const Window = windowFile.Window;
const WindowConfig = windowFile.WindowConfig;

pub fn run(allocator: std.mem.Allocator, io: std.Io) void {
    const config = WindowConfig{
        .width = 600,
        .height = 600,
        .title = "Engine",
        .api = .opengl,
    };

    const window = Window.init(allocator, config) catch |err| {
        std.debug.print("Failed to initialize window: {}", .{err});
        return;
    };
    defer window.deinit(allocator);

    // Initialize our hardware bridge context cleanly
    var renderer = IRenderer.init(allocator, window.api) catch |err| {
        std.debug.print("Failed to initialize renderer: {}", .{err});
        return;
    };
    defer renderer.deinit();

    // 1. Define the geometric data container (Pure Data)
    // 1. Define the geometric data container (24 Vertices for independent UV mapping)
    const vertices = [_]f32{
        // Position            // Color          // UVs
        // Front Face
        -0.5, -0.5, 0.5, 1.0, 1.0, 1.0, 0.0, 0.0, // Bottom-left
        0.5, -0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 0.0, // Bottom-right
        0.5, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0, // Top-right
        -0.5, 0.5, 0.5, 1.0, 1.0, 1.0, 0.0, 1.0, // Top-left

        // Back Face
        -0.5, -0.5, -0.5, 1.0, 1.0, 1.0, 1.0, 0.0, // Bottom-right
        -0.5, 0.5, -0.5, 1.0, 1.0, 1.0, 1.0, 1.0, // Top-right
        0.5, 0.5, -0.5, 1.0, 1.0, 1.0, 0.0, 1.0, // Top-left
        0.5,  -0.5, -0.5, 1.0, 1.0, 1.0, 0.0, 0.0, // Bottom-left

        // Top Face
        -0.5, 0.5,  -0.5, 1.0, 1.0, 1.0, 0.0, 1.0,
        -0.5, 0.5,  0.5,  1.0, 1.0, 1.0, 0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 1.0, 1.0, 1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0, 1.0, 1.0, 1.0,

        // Bottom Face
        -0.5, -0.5, -0.5, 1.0, 1.0, 1.0, 1.0, 1.0,
        0.5,  -0.5, -0.5, 1.0, 1.0, 1.0, 0.0, 1.0,
        0.5,  -0.5, 0.5,  1.0, 1.0, 1.0, 0.0, 0.0,
        -0.5, -0.5, 0.5,  1.0, 1.0, 1.0, 1.0, 0.0,

        // Right Face
        0.5,  -0.5, -0.5, 1.0, 1.0, 1.0, 1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0, 1.0, 1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 1.0, 1.0, 0.0, 1.0,
        0.5,  -0.5, 0.5,  1.0, 1.0, 1.0, 0.0, 0.0,

        // Left Face
        -0.5, -0.5, -0.5, 1.0, 1.0, 1.0, 0.0, 0.0,
        -0.5, -0.5, 0.5,  1.0, 1.0, 1.0, 1.0, 0.0,
        -0.5, 0.5,  0.5,  1.0, 1.0, 1.0, 1.0, 1.0,
        -0.5, 0.5,  -0.5, 1.0, 1.0, 1.0, 0.0, 1.0,
    };

    const indices = [_]u32{
        // Front face (Counter-Clockwise winding)
        0,  1,  2,
        2,  3,  0,

        // Back face
        4,  5,  6,
        6,  7,  4,

        // Top face
        8,  9,  10,
        10, 11, 8,

        // Bottom face
        12, 13, 14,
        14, 15, 12,

        // Right face
        16, 17, 18,
        18, 19, 16,

        // Left face
        20, 21, 22,
        22, 23, 20,
    };

    // Describe the attributes packed in our float array
    const attrs = [_]VertexAttribute{
        .{ .location = 0, .type = .float3 }, // Position
        .{ .location = 1, .type = .float3 }, // Color
        .{ .location = 2, .type = .float2 }, // UV
    };

    const mesh = Mesh{
        .vertices = &vertices,
        .indices = &indices,
        .layout = .{
            .attributes = &attrs,
            .stride = @sizeOf(f32) * 8, // Total float block size per vertex
        },
    };

    // 2. Initialize Material and Texture Assets
    zstbi.init(io, allocator);
    defer zstbi.deinit();
    zstbi.setFlipVerticallyOnLoad(true);

    const wall_texture = ITexture.init(window.api, "wall.jpg", .{
        .filter = .nearest,
        .wrap = .repeat,
        .generate_mipmaps = false,
    }) catch |err| {
        std.debug.print("Failed to initialize wall texture: {}", .{err});
        return;
    };
    defer wall_texture.deinit();

    const smiley_texture = ITexture.init(window.api, "smiley.jpg", .{
        .filter = .nearest,
        .wrap = .repeat,
        .generate_mipmaps = false,
    }) catch |err| {
        std.debug.print("Failed to initialize smiley texture: {}", .{err});
        return;
    };
    defer smiley_texture.deinit();

    var material = Material.init(allocator, "basic_unlit_shader");
    defer material.deinit();

    material.addTexture(wall_texture) catch |err| {
        std.debug.print("Failed to add wall texture: {}", .{err});
        return;
    };
    material.addTexture(smiley_texture) catch |err| {
        std.debug.print("Failed to add smiley texture: {}", .{err});
        return;
    };

    // Set stable property parameters on the material mapping layer
    material.set("useUniformColor", .{ .boolean = true }) catch |err| {
        std.debug.print("Failed to set useUniformColor: {}", .{err});
        return;
    };
    material.set("useUniformTexture", .{ .boolean = true }) catch |err| {
        std.debug.print("Failed to set useUniformTexture: {}", .{err});
        return;
    };

    const scaling = zlm.Mat4.createScale(0.5, 0.5, 0.5);
    var rotation: zlm.Mat4 = undefined;
    var transform: zlm.Mat4 = undefined;
    var time: f32 = undefined;
    var red_value: f32 = undefined;
    var green_value: f32 = undefined;
    var blue_value: f32 = undefined;

    // --- Core Engine Loop ---
    while (!window.shouldClose()) {
        window.pollEvents();

        while (window.nextEvent()) |event| {
            switch (event) {
                .key_press => |e| {
                    if (e.key == .escape) window.handle.setShouldClose(true);
                },
                .window_resize => |e| {
                    // Handled inside backend implementations via renderer boundary mapping
                    if (window.api == .opengl) {
                        @import("zopengl").bindings.viewport(0, 0, e.width, e.height);
                    }
                },
                else => {},
            }
        }

        // Clear the frame buffers context cleanly
        renderer.beginFrame(0.1, 0.2, 0.3, 1.0);

        // Calculate runtime dynamic attributes
        // NOTE: For clean application patterns, look into wrapping glfw.getTime into window.getTime()
        time = @floatCast(@import("zglfw").getTime());
        red_value = (std.math.sin(time) / 1.0) + 0.5;
        green_value = (std.math.sin(time) / 2.0) + 0.5;
        blue_value = (std.math.sin(time) / 3.0) + 0.5;

        rotation = zlm.Mat4.createAngleAxis(zlm.Vec3.new(0.0, 1.0, 1.0), time);
        transform = rotation.mul(scaling);

        // Update parameters inside our data tables
        material.set("transform", .{ .mat4 = transform }) catch |err| {
            std.debug.print("Failed to set transform: {}", .{err});
            return;
        };
        material.set("colorFromUniform", .{ .vec4 = .{ red_value, green_value, blue_value, 1.0 } }) catch |err| {
            std.debug.print("Failed to set colorFromUniform: {}", .{err});
            return;
        };

        // Draw! The backend interface reads our pure CPU configurations and maps the pipeline calls
        renderer.draw(mesh, material);

        window.swapBuffers();
    }
}
