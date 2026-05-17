const std = @import("std");
const ITexture = @import("interfaces/Itexture.zig").ITexture;
const zlm = @import("zlm").as(f32);
const BoundedArray = @import("../core/collections/bounded_array.zig").BoundedArray;

pub const UniformValue = union(enum) {
    boolean: bool,
    float: f32,
    vec2: [2]f32,
    vec3: [3]f32,
    vec4: [4]f32,
    mat4: zlm.Mat4,
};

pub const Material = struct {
    shader_name: []const u8, // E.g., "basic_lit"
    uniforms: std.StringHashMap(UniformValue),
    textures: BoundedArray(ITexture, 8),

    pub fn init(allocator: std.mem.Allocator, shader_name: []const u8) Material {
        return .{
            .shader_name = shader_name,
            .uniforms = std.StringHashMap(UniformValue).init(allocator),
            .textures = BoundedArray(ITexture, 8).init(),
        };
    }

    pub fn deinit(self: *Material) void {
        self.uniforms.deinit();
    }

    pub fn set(self: *Material, name: []const u8, value: UniformValue) !void {
        try self.uniforms.put(name, value);
    }

    pub fn addTexture(self: *Material, texture: ITexture) !void {
        try self.textures.append(texture);
    }
};
