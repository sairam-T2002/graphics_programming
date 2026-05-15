const zgl = @import("zopengl");
const gl = zgl.bindings;

pub const VertexBuffer = struct {
    id: u32,
    count: usize,

    pub fn init(vertices: []const f32) VertexBuffer {
        var id: u32 = undefined;

        gl.genBuffers(1, &id);
        gl.bindBuffer(gl.ARRAY_BUFFER, id);
        // Copying vertices from RAM (Zig array) to VRAM (GPU)
        gl.bufferData(gl.ARRAY_BUFFER, @intCast(vertices.len * @sizeOf(f32)), vertices.ptr, gl.STATIC_DRAW);

        return .{ .id = id, .count = vertices.len };
    }

    pub fn bind(self: VertexBuffer) void {
        gl.bindBuffer(gl.ARRAY_BUFFER, self.id);
    }

    pub fn unbind(self: VertexBuffer) void {
        _ = self;
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    }

    pub fn deinit(self: VertexBuffer) void {
        gl.deleteBuffers(1, &self.id);
    }
};

pub const IndexBuffer = struct {
    id: u32,
    count: usize,

    pub fn init(indices: []const u32) IndexBuffer {
        var id: u32 = undefined;

        gl.genBuffers(1, &id);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, id);
        // Copying vertices from RAM (Zig array) to VRAM (GPU)
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(indices.len * @sizeOf(u32)), indices.ptr, gl.STATIC_DRAW);

        return .{ .id = id, .count = indices.len };
    }

    pub fn bind(self: IndexBuffer) void {
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.id);
    }

    pub fn unbind(self: IndexBuffer) void {
        _ = self;
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    }

    pub fn deinit(self: IndexBuffer) void {
        gl.deleteBuffers(1, &self.id);
    }
};
