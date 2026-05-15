const zgl = @import("zopengl");
const gl = zgl.bindings;
const buffers = @import("buffers.zig");

pub const VertexArray = struct {
    id: u32,
    vertex_buffer: buffers.VertexBuffer,
    index_buffer: buffers.IndexBuffer,

    pub fn init(vertices: []const f32, indicies: []const u32) VertexArray {
        var id: u32 = undefined;
        gl.genVertexArrays(1, &id);
        gl.bindVertexArray(id);
        return .{
            .id = id,
            .vertex_buffer = buffers.VertexBuffer.init(vertices),
            .index_buffer = buffers.IndexBuffer.init(indicies),
        };
    }

    pub fn bind(self: VertexArray) void {
        gl.bindVertexArray(self.id);
    }

    pub fn AddAttribPointer(self: VertexArray, location: u32, size: i32, stride: i32, offset_ptr: ?*const anyopaque) void {
        self.bind(); // Ensure THIS VAO is bound before modifying its stat
        self.vertex_buffer.bind(); // this is to ensure we are pointing to the correct VBO
        gl.vertexAttribPointer(location, size, gl.FLOAT, gl.FALSE, stride, offset_ptr);
        gl.enableVertexAttribArray(location);
    }

    pub fn unbind(self: VertexArray) void {
        _ = self;
        gl.bindVertexArray(0);
    }

    pub fn deinit(self: VertexArray) void {
        // Delete the buffers first
        self.vertex_buffer.deinit();
        self.index_buffer.deinit();
        // Then delete the VAO
        gl.deleteVertexArrays(1, &self.id);
    }
};
