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
    pub fn duplicate(self: *StackStack) !void {
        return self.toss.*.duplicate();
    }
    pub fn init(allocator: std.mem.Allocator) !StackStack {
        var ss = std.ArrayList(stack.Stack).init(allocator);
        errdefer ss.deinit();
        var toss = try ss.addOne();
        toss.* = stack.Stack.init(allocator);
        return StackStack{
            .data = ss,
            .toss = toss,
        };
    }
    pub fn pop(self: *StackStack) i64 {
        return self.toss.*.pop();
    }
    pub fn popVector(self: *StackStack) [2]i64 {
        return self.toss.*.popVector();
    }
    pub fn push(self: *StackStack, n: i64) !void {
        return self.toss.*.append(n);
    }
    pub fn pushVector(self: *StackStack, v: [2]i64) !void {
        return self.toss.*.pushVector(v);
    }
    pub fn swap(self: *StackStack) !void {
        return self.toss.*.swap();
    }
};

test "all" {
    std.testing.refAllDecls(@This());
}
