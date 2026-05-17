const std = @import("std");
const gl = @import("zopengl").bindings;
const zstbi = @import("zstbi");

pub const FilterMode = enum {
    linear,
    nearest,
};

pub const WrapMode = enum {
    repeat,
    clamp_to_edge,
    mirrored_repeat,
};

pub const TextureConfig = struct {
    filter: FilterMode = .linear,
    wrap: WrapMode = .repeat,
    generate_mipmaps: bool = true,
};

pub const Texture = struct {
    id: c_uint,
    width: i32,
    height: i32,

    pub fn init(path: [:0]const u8, config: TextureConfig) !Texture {
        var image = try zstbi.Image.loadFromFile(path, 0);
        defer image.deinit();

        var texture_id: c_uint = undefined;
        gl.genTextures(1, &texture_id);
        gl.bindTexture(gl.TEXTURE_2D, texture_id);

        // Map Wrap Mode
        const gl_wrap: gl.Enum = switch (config.wrap) {
            .repeat => gl.REPEAT,
            .clamp_to_edge => gl.CLAMP_TO_EDGE,
            .mirrored_repeat => gl.MIRRORED_REPEAT,
        };
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, @intCast(gl_wrap));
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, @intCast(gl_wrap));

        // Map Filter Mode
        const min_filter: gl.Enum = if (config.generate_mipmaps)
            (if (config.filter == .linear) gl.LINEAR_MIPMAP_LINEAR else gl.NEAREST_MIPMAP_NEAREST)
        else
            (if (config.filter == .linear) gl.LINEAR else gl.NEAREST);

        const mag_filter: gl.Enum = if (config.filter == .linear) gl.LINEAR else gl.NEAREST;

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, @intCast(min_filter));
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, @intCast(mag_filter));

        const format: gl.Enum = if (image.num_components == 4) gl.RGBA else gl.RGB;

        gl.texImage2D(gl.TEXTURE_2D, 0, @intCast(format), @intCast(image.width), @intCast(image.height), 0, format, gl.UNSIGNED_BYTE, image.data.ptr);

        if (config.generate_mipmaps) {
            gl.generateMipmap(gl.TEXTURE_2D);
        }

        return .{
            .id = texture_id,
            .width = @intCast(image.width),
            .height = @intCast(image.height),
        };
    }

    pub fn deinit(self: Texture) void {
        gl.deleteTextures(1, &self.id);
    }

    pub fn bind(self: Texture, unit: u32) void {
        gl.activeTexture(@intCast(gl.TEXTURE0 + unit));
        gl.bindTexture(gl.TEXTURE_2D, self.id);
    }
};
