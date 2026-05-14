const std = @import("std");
const root = @import("runtime");

pub fn main(init: std.process.Init) !void {
    try root.run(init);
}
