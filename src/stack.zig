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
        try self.data.appendSlice(v[0..]);
    }
    test "pushVector" {
        var s = Stack.init(std.testing.allocator);
        defer s.deinit();
        try s.pushVector([2]i64{ 1, -1 });
        try s.pushVector([2]i64{ 2, -2 });
        try std.testing.expectEqual(s.data.items.len, 4);
        try std.testing.expectEqual(s.data.items[0], 1);
        try std.testing.expectEqual(s.data.items[1], -1);
        try std.testing.expectEqual(s.data.items[2], 2);
        try std.testing.expectEqual(s.data.items[3], -2);
    }
    pub fn swap(self: *Stack) !void {
        const v = self.popVector();
        try self.pushVector([2]i64{ v[1], v[0] });
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
    //pub fn transfert(toss: *Stack, soss: *Stack, n: u64) !void {
    //}
};

test "all" {
    std.testing.refAllDecls(@This());
}
