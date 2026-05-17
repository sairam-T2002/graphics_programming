const std = @import("std");
const windowFile = @import("../../core/window.zig");
const opengl = @import("../opengl/texture.zig");

pub const ITexture = union(enum) {
    opengl: opengl.Texture,
    // webgpu: webgpu.Texture,

    pub fn init(api: windowFile.GraphicsApi, path: [:0]const u8, config: opengl.TextureConfig) !ITexture {
        return switch (api) {
            .opengl => .{ .opengl = try opengl.Texture.init(path, config) },
            else => return error.ApiNotSupported,
        };
    }

    pub fn deinit(self: ITexture) void {
        switch (self) {
            .opengl => |t| t.deinit(),
        }
    }

    pub fn bind(self: ITexture, unit: u32) void {
        switch (self) {
            .opengl => |t| t.bind(unit),
        }
    }
};
