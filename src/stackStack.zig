const std = @import("std");
const stack = @import("stack.zig");
const vector = std.meta.Vector(2, i64);

pub const StackStack = struct {
    data: std.ArrayList(stack.Stack),
    toss: *stack.Stack,
    pub fn deinit(self: *StackStack) void {
        for (self.data.items) |*s| {
            s.deinit();
        }
        self.data.deinit();
    }
    pub fn init(allocator: std.mem.Allocator) !StackStack {
        var ss = std.ArrayList(stack.Stack).init(allocator);
        errdefer ss.deinit();
        var s = try ss.addOne();
        s.* = stack.Stack.init(allocator);
        return StackStack{
            .data = ss,
            .toss = s,
        };
    }
    pub inline fn toss(self: *StackStack) *stack.Stack {
        return self.toss;
    }
};

test "all" {
    std.testing.refAllDecls(@This());
}
