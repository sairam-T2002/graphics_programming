const std = @import("std");

pub fn BoundedArray(comptime T: type, comptime capacity: usize) type {
    return struct {
        buffer: [capacity]T = undefined,
        len: usize = 0,

        pub fn init() @This() {
            return .{};
        }

        pub fn append(self: *@This(), item: T) !void {
            if (self.len >= capacity) return error.Overflow;
            self.buffer[self.len] = item;
            self.len += 1;
        }

        pub fn constSlice(self: *const @This()) []const T {
            return self.buffer[0..self.len];
        }
    };
}
