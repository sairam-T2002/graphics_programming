const std = @import("std");
const root = @import("runtime");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    try root.run(allocator);
}
