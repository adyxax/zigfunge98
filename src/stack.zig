const std = @import("std");
const vector = std.meta.Vector(2, i64);

pub const Stack = struct {
    data: std.ArrayList(i64),
    pub fn clear(self: *Stack) void {
        self.data.clearRetainingCapacity();
    }
    pub fn deinit(self: *Stack) void {
        self.data.deinit();
    }
    pub fn duplicate(self: *Stack) !void {
        if (self.data.items.len > 0) {
            try self.push(self.data.items[self.data.items.len - 1]);
        }
    }
    pub fn init(allocator: std.mem.Allocator) Stack {
        return Stack{
            .data = std.ArrayList(i64).init(allocator),
        };
    }
    pub fn pop(self: *Stack) i64 {
        return if (self.data.popOrNull()) |v| v else 0;
    }
    pub fn popVector(self: *Stack) [2]i64 {
        const b = if (self.data.popOrNull()) |v| v else 0;
        const a = if (self.data.popOrNull()) |v| v else 0;
        return [2]i64{ a, b };
    }
    pub fn push(self: *Stack, n: i64) !void {
        try self.data.append(n);
    }
    pub fn pushVector(self: *Stack, v: [2]i64) !void {
        try self.data.appendSlice(v[0..2]);
    }
    pub fn swap(self: *Stack) !void {
        const v = self.popVector();
        try self.pushVector([2]i64{ v[1], v[0] });
    }
};

test "all" {
    std.testing.refAllDecls(@This());
}

test "clear" {
    var s = Stack.init(std.testing.allocator);
    defer s.deinit();
    s.clear();
    try std.testing.expect(s.pop() == 0);
    try s.pushVector([2]i64{ 1, 2 });
    s.clear();
    try std.testing.expect(s.pop() == 0);
}
test "duplicate" {
    var s = Stack.init(std.testing.allocator);
    defer s.deinit();
    try s.duplicate();
    try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 0, 0 }));
    try s.pushVector([2]i64{ 1, 2 });
    try s.duplicate();
    try s.duplicate();
    try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 2, 2 }));
    try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 1, 2 }));
}
test "push and pop" {
    var s = Stack.init(std.testing.allocator);
    defer s.deinit();
    try std.testing.expect(s.pop() == 0);
    try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 0, 0 }));
    try s.push(1);
    try std.testing.expect(s.pop() == 1);
    try std.testing.expect(s.pop() == 0);
    try s.pushVector([2]i64{ 2, 3 });
    try std.testing.expect(s.pop() == 3);
    try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 0, 2 }));
}
test "swap" {
    var s = Stack.init(std.testing.allocator);
    defer s.deinit();
    try s.swap();
    try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 0, 0 }));
    try s.push(1);
    try s.swap();
    try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 1, 0 }));
    try s.push(2);
    try s.swap();
    try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 2, 0 }));
}
