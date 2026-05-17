const std = @import("std");
const zgl = @import("zopengl");
const gl = zgl.bindings;

pub const Shader = struct {
    program_id: c_uint,
    vertex_shader_id: c_uint,
    fragment_shader_id: c_uint,

    pub fn init(vertex_shader_source: [:0]const u8, fragment_shader_source: [:0]const u8) Shader {
        const vertex_shader_id = _createShader(vertex_shader_source, gl.VERTEX_SHADER);
        const fragment_shader_id = _createShader(fragment_shader_source, gl.FRAGMENT_SHADER);

        const program_id = gl.createProgram();
        gl.attachShader(program_id, vertex_shader_id);
        gl.attachShader(program_id, fragment_shader_id);
        gl.linkProgram(program_id);

        // Program Link Check
        var success: i32 = undefined;
        gl.getProgramiv(program_id, gl.LINK_STATUS, &success);
        if (success == 0) {
            var info_log: [512]u8 = undefined;
            gl.getProgramInfoLog(program_id, 512, null, &info_log);
            std.debug.print("Program Link Error: {s}\n", .{info_log[0..]});
        }

        return Shader{
            .program_id = program_id,
            .vertex_shader_id = vertex_shader_id,
            .fragment_shader_id = fragment_shader_id,
        };
    }

    pub fn useProgram(self: Shader) void {
        gl.useProgram(self.program_id);
    }

    pub fn deleteProgram(self: Shader) void {
        gl.deleteProgram(self.program_id);
    }

    pub fn deleteVertexShader(self: Shader) void {
        gl.deleteShader(self.vertex_shader_id);
    }

    pub fn deleteFragmentShader(self: Shader) void {
        gl.deleteShader(self.fragment_shader_id);
    }

    pub fn setBool(self: Shader, name: [:0]const u8, value: bool) void {
        const loc = gl.getUniformLocation(self.program_id, name);
        gl.uniform1i(loc, if (value) 1 else 0);
    }

    pub fn setInt(self: Shader, name: [:0]const u8, value: c_int) void {
        const loc = gl.getUniformLocation(self.program_id, name);
        gl.uniform1i(loc, value);
    }

    pub fn setFloatVec4(self: Shader, name: [:0]const u8, x: f32, y: f32, z: f32, w: f32) void {
        const loc = gl.getUniformLocation(self.program_id, name);
        gl.uniform4f(loc, x, y, z, w);
    }

    pub fn setFloatVec3(self: Shader, name: [:0]const u8, x: f32, y: f32, z: f32) void {
        const loc = gl.getUniformLocation(self.program_id, name);
        gl.uniform3f(loc, x, y, z);
    }

    pub fn setFloatVec2(self: Shader, name: [:0]const u8, x: f32, y: f32) void {
        const loc = gl.getUniformLocation(self.program_id, name);
        gl.uniform2f(loc, x, y);
    }

    /// Sets a 4x4 matrix uniform.
    /// Accepts a raw slice/array of 16 floats, or a zlm.Mat4 type directly.
    pub fn setMat4(self: Shader, name: [:0]const u8, mat: anytype, transpose: gl.Boolean) void {
        const T = @TypeOf(mat);
        const loc = gl.getUniformLocation(self.program_id, name);

        // Check if it's a zlm matrix (which contains a 'fields' declaration)
        if (@hasDecl(T, "fields")) {
            const ptr: [*]const f32 = @ptrCast(&mat.fields);
            gl.uniformMatrix4fv(loc, 1, transpose, ptr);
        } else if (T == []const f32 or T == []f32) {
            std.debug.assert(mat.len == 16);
            gl.uniformMatrix4fv(loc, 1, transpose, mat.ptr);
        } else {
            // Handles fixed-size arrays like [16]f32 or [4][4]f32
            const ptr: [*]const f32 = @ptrCast(&mat);
            gl.uniformMatrix4fv(loc, 1, transpose, ptr);
        }
    }

    /// Sets a 3x3 matrix uniform.
    /// Accepts a raw slice/array of 9 floats, or a zlm.Mat3 type directly.
    pub fn setMat3(self: Shader, name: [:0]const u8, mat: anytype, transpose: gl.GLboolean) void {
        const T = @TypeOf(mat);
        const loc = gl.getUniformLocation(self.program_id, name);

        if (@hasDecl(T, "fields")) {
            const ptr: [*]const f32 = @ptrCast(&mat.fields);
            gl.uniformMatrix3fv(loc, 1, transpose, ptr);
        } else if (T == []const f32 or T == []f32) {
            std.debug.assert(mat.len == 9);
            gl.uniformMatrix3fv(loc, 1, transpose, mat.ptr);
        } else {
            const ptr: [*]const f32 = @ptrCast(&mat);
            gl.uniformMatrix3fv(loc, 1, transpose, ptr);
        }
    }

    fn _createShader(source: [:0]const u8, shader_type: c_uint) c_uint {
        const shader = gl.createShader(shader_type);
        const ptr: ?[*]const u8 = source.ptr;
        gl.shaderSource(shader, 1, @ptrCast(&ptr), null);
        gl.compileShader(shader);

        var success: i32 = undefined;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            var info_log: [512]u8 = undefined;
            gl.getShaderInfoLog(shader, 512, null, &info_log);
            const s_type = if (shader_type == gl.VERTEX_SHADER) "Vertex" else "Fragment";
            std.debug.print("{s} Shader Error: {s}\n", .{ s_type, info_log[0..] });
        }

        return shader;
    }
};
