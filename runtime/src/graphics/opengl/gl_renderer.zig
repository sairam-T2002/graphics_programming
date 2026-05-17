const std = @import("std");
const zgl = @import("zopengl");
const gl = zgl.bindings;
const glfw = @import("zglfw");

const Mesh = @import("../mesh.zig").Mesh;
const Material = @import("../material.zig").Material;
const VertexArray = @import("vertex_array.zig").VertexArray;
const Shader = @import("shader.zig").Shader;

pub const GLRenderer = struct {
    shader_program: Shader,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !GLRenderer {
        try zgl.loadCoreProfile(glfw.getProcAddress, 4, 6);
        const shader = Shader.init(@embedFile("shaders/vert.glsl"), @embedFile("shaders/frag.glsl"));
        return .{
            .shader_program = shader,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *GLRenderer) void {
        self.shader_program.deleteProgram();
    }

    pub fn beginFrame(_: GLRenderer, r: f32, g: f32, b: f32, a: f32) void {
        gl.clearColor(r, g, b, a);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    }

    pub fn draw(self: GLRenderer, mesh: Mesh, material: Material) void {
        // setup face culling
        if (mesh.cull_backfaces) {
            gl.enable(gl.CULL_FACE);
            gl.cullFace(gl.BACK);
            gl.frontFace(gl.CCW);
        } else {
            gl.disable(gl.CULL_FACE);
        }

        // 1. Set up temporary or cached Vertex Array matching common mesh geometry
        const vao = VertexArray.init(mesh.vertices, mesh.indices);
        defer vao.deinit();

        var offset_bytes: usize = 0;
        for (mesh.layout.attributes) |attr| {
            const count: i32 = switch (attr.type) {
                .float => 1,
                .float2 => 2,
                .float3 => 3,
                .float4 => 4,
            };

            // Calculate pointer offset safely without causing modern compiler errors
            const offset_ptr: ?*const anyopaque = if (offset_bytes == 0) null else @ptrFromInt(offset_bytes);

            vao.AddAttribPointer(attr.location, count, @intCast(mesh.layout.stride), offset_ptr);
            offset_bytes += attr.getSize();
        }

        // 2. Bind Shader program
        self.shader_program.useProgram();

        // 3. Apply uniform values mapped out of our agnostic Material description
        var it = material.uniforms.iterator();
        while (it.next()) |entry| {
            const name = entry.key_ptr.*;
            var name_buf: [64]u8 = undefined;
            const gl_name = std.fmt.bufPrintZ(&name_buf, "{s}", .{name}) catch continue;

            switch (entry.value_ptr.*) {
                .boolean => |v| self.shader_program.setBool(gl_name, v),
                .float => |v| {
                    const loc = gl.getUniformLocation(self.shader_program.program_id, gl_name);
                    gl.uniform1f(loc, v);
                },
                .vec4 => |v| self.shader_program.setFloatVec4(gl_name, v[0], v[1], v[2], v[3]),
                .mat4 => |v| self.shader_program.setMat4(gl_name, v, gl.FALSE),
                else => {},
            }
        }

        // 4. Bind Textures from Material slot positions
        for (material.textures.constSlice(), 0..) |texture, unit| {
            texture.bind(@intCast(unit));

            var buf: [32]u8 = undefined;
            // Catch the potential error right at the assignment expression point
            if (std.fmt.bufPrintZ(&buf, "textureFromProgram{d}", .{unit + 1})) |tex_uniform| {
                self.shader_program.setInt(tex_uniform, @intCast(unit));
            } else |_| {}
        }

        // 5. Draw command execution
        vao.bind();
        gl.drawElements(gl.TRIANGLES, @intCast(mesh.index_count()), gl.UNSIGNED_INT, null);
    }
};
