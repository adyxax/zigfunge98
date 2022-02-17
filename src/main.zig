const std = @import("std");
const stack = @import("stack.zig");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "all" {
    std.testing.refAllDecls(@This());
}
