const std = @import("std");
const vector = std.meta.Vector(2, i64);

pub const Stack = struct {
    allocator: std.mem.Allocator,
    data: std.ArrayList(i64),
    pub fn clear(self: *Stack) void {
        self.data.clearRetainingCapacity();
    }
    pub fn deinit(self: *Stack) void {
        self.data.deinit();
        self.allocator.destroy(self);
    }
    pub fn duplicate(self: *Stack) !void {
        if (self.data.items.len > 0) {
            try self.push(self.data.items[self.data.items.len - 1]);
        }
    }
    test "duplicate" {
        var s = try Stack.init(std.testing.allocator);
        defer s.deinit();
        try s.duplicate();
        try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 0, 0 }));
        try s.pushVector([2]i64{ 1, 2 });
        try s.duplicate();
        try s.duplicate();
        try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 2, 2 }));
        try std.testing.expectEqual(s.popVector(), @as(vector, [2]i64{ 1, 2 }));
    }
    pub fn init(allocator: std.mem.Allocator) !*Stack {
        var s = try allocator.create(Stack);
        s.allocator = allocator;
        s.data = std.ArrayList(i64).init(allocator);
        return s;
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
        var s = try Stack.init(std.testing.allocator);
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
        var s = try Stack.init(std.testing.allocator);
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
    pub fn transfert(toss: *Stack, soss: *Stack, n: u64) !void {
        // Implements a value transfert between two stacks, intended for use with the '{'
        // (aka begin) and '}' (aka end) stackstack commands
        try toss.data.ensureUnusedCapacity(n);
        var i: usize = n;
        while (i >= std.math.min(soss.data.items.len, n) + 1) : (i -= 1) {
            toss.data.appendAssumeCapacity(0);
        }
        while (i >= 1) : (i -= 1) {
            toss.data.appendAssumeCapacity(soss.data.items[soss.data.items.len - i]);
        }
        if (soss.data.items.len >= n) {
            soss.data.items.len -= n;
        } else {
            soss.data.items.len = 0;
        }
    }
    test "transfert" {
        var empty = try Stack.init(std.testing.allocator);
        defer empty.deinit();
        var empty2 = try Stack.init(std.testing.allocator);
        defer empty2.deinit();
        try empty.transfert(empty2, 4);
        const emptyResult = [_]i64{ 0, 0, 0, 0 };
        try std.testing.expectEqualSlices(i64, empty.data.items, emptyResult[0..]);
        const empty2Result = [_]i64{};
        try std.testing.expectEqualSlices(i64, empty2.data.items, empty2Result[0..]);
        try empty.transfert(empty2, 32);
        try std.testing.expectEqual(empty.data.items.len, 36);
        empty.clear();
        var some = try Stack.init(std.testing.allocator);
        defer some.deinit();
        try some.push(2);
        try empty.transfert(some, 3);
        const emptyResult2 = [_]i64{ 0, 0, 2 };
        try std.testing.expectEqualSlices(i64, empty.data.items, emptyResult2[0..]);
        try std.testing.expectEqualSlices(i64, some.data.items, empty2Result[0..]);
        empty.clear();
        var full = try Stack.init(std.testing.allocator);
        defer full.deinit();
        try full.push(1);
        try full.push(2);
        try full.push(3);
        try empty.transfert(full, 2);
        const emptyResult3 = [_]i64{ 2, 3 };
        try std.testing.expectEqualSlices(i64, empty.data.items, emptyResult3[0..]);
        const fullResult = [_]i64{1};
        try std.testing.expectEqualSlices(i64, full.data.items, fullResult[0..]);
    }
    pub fn discard(self: *Stack, n: u64) void {
        // Implements a discard mechanism intended for use with the '}'(aka end) stackstack command
        if (self.data.items.len > n) {
            self.data.items.len -= n;
        } else {
            self.data.items.len = 0;
        }
    }
    test "discard" {
        var empty = try Stack.init(std.testing.allocator);
        defer empty.deinit();
        empty.discard(1);
        const emptyResult = [_]i64{};
        try std.testing.expectEqualSlices(i64, empty.data.items, emptyResult[0..]);
        try empty.push(2);
        empty.discard(3);
        try std.testing.expectEqualSlices(i64, empty.data.items, emptyResult[0..]);
        try empty.push(4);
        try empty.push(5);
        try empty.push(6);
        empty.discard(1);
        const emptyResult2 = [_]i64{ 4, 5 };
        try std.testing.expectEqualSlices(i64, empty.data.items, emptyResult2[0..]);
    }
    pub fn yCommandPick(self: *Stack, n: usize, h: usize) !void {
        if (n > self.data.items.len) {
            self.data.items.len = 1;
            self.data.items[0] = 0;
        } else {
            const v = self.data.items[self.data.items.len - n];
            self.data.items.len = h;
            try self.push(v);
        }
    }
};

test "all" {
    std.testing.refAllDecls(@This());
}
