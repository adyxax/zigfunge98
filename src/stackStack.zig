const std = @import("std");
const stack = @import("stack.zig");

pub const StackStack = struct {
    allocator: std.mem.Allocator,
    data: std.ArrayList(*stack.Stack),
    toss: *stack.Stack,
    pub fn deinit(self: *StackStack) void {
        for (self.data.items) |s| {
            s.deinit();
        }
        self.data.deinit();
        self.allocator.destroy(self);
    }
    pub fn init(allocator: std.mem.Allocator) !*StackStack {
        var ss = try allocator.create(StackStack);
        errdefer allocator.destroy(ss);
        ss.allocator = allocator;
        ss.data = std.ArrayList(*stack.Stack).init(allocator);
        errdefer ss.data.deinit();
        var s = try ss.data.addOne();
        s.* = try stack.Stack.init(allocator);
        ss.toss = s.*;
        return ss;
    }
    pub inline fn toss(self: *StackStack) *stack.Stack {
        return self.toss;
    }
};

test "all" {
    std.testing.refAllDecls(@This());
}
