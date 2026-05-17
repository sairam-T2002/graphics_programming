const std = @import("std");

pub const VertexAttributeType = enum { float, float2, float3, float4 };

pub const VertexAttribute = struct {
    location: u32,
    type: VertexAttributeType,

    pub fn getSize(self: VertexAttribute) u32 {
        return switch (self.type) {
            .float => 4,
            .float2 => 8,
            .float3 => 12,
            .float4 => 16,
        };
    }
};

pub const VertexLayout = struct {
    attributes: []const VertexAttribute,
    stride: u32,

    pub fn calculateStride(attributes: []const VertexAttribute) u32 {
        var stride: u32 = 0;
        for (attributes) |attr| {
            stride += attr.getSize();
        }
        return stride;
    }
};

pub const Mesh = struct {
    vertices: []const f32,
    indices: []const u32,
    layout: VertexLayout,

    // Pure data container—no init/deinit tracking graphics context states
};
