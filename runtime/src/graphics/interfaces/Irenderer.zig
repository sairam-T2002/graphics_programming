const std = @import("std");
const windowFile = @import("../../core/window.zig");
const Mesh = @import("../mesh.zig").Mesh;
const Material = @import("../material.zig").Material;

// Backend Implementations
const GLRenderer = @import("../opengl/gl_renderer.zig").GLRenderer;
// const WGPURenderer = @import("../webgpu/wgpu_renderer.zig").WGPURenderer;

pub const IRenderer = union(enum) {
    opengl: GLRenderer,
    // webgpu: WGPURenderer,

    pub fn init(allocator: std.mem.Allocator, api: windowFile.GraphicsApi) !IRenderer {
        return switch (api) {
            .opengl => .{ .opengl = try GLRenderer.init(allocator) },
            else => return error.ApiNotSupported,
        };
    }

    pub fn deinit(self: *IRenderer) void {
        switch (self.*) {
            .opengl => |*r| r.deinit(),
        }
    }

    pub fn beginFrame(self: IRenderer, r: f32, g: f32, b: f32, a: f32) void {
        switch (self) {
            .opengl => |r_ctx| r_ctx.beginFrame(r, g, b, a),
        }
    }

    /// The Renderer handles compile-on-demand or retrieval of hardware pipelines
    /// by consuming the API-agnostic common Mesh and Material structures!
    pub fn draw(self: IRenderer, mesh: Mesh, material: Material) void {
        switch (self) {
            .opengl => |r_ctx| r_ctx.draw(mesh, material),
        }
    }
};
