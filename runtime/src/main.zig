const std = @import("std");
const root = @import("runtime");

pub fn main(init: std.process.Init) void {
    const allocator = init.gpa;
    const io: std.Io = init.io;

    root.run(allocator, io);
}
