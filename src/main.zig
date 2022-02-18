const std = @import("std");
const stackStack = @import("stackStack.zig");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "all" {
    std.testing.refAllDecls(@This());
}
