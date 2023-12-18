const std = @import("std");
const stack = @import("stack.zig");

pub const StackStack = struct {
    allocator: std.mem.Allocator,
    data: std.ArrayList(*stack.Stack),
    toss: *stack.Stack,
    pub fn deinit(self: *StackStack) void {
        self.toss.deinit();
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
        ss.toss = try stack.Stack.init(allocator);
        return ss;
    }
    pub fn begin(self: *StackStack, v: [2]i64) !void {
        var soss = self.toss;
        try self.data.append(soss);
        const n = soss.pop();
        self.toss = try stack.Stack.init(self.allocator);
        if (n > 0) {
            try self.toss.transfert(soss, @intCast(n));
        } else if (n < 0) {
            var i: usize = 0;
            while (i < -n) : (i += 1) {
                try soss.push(0);
            }
        }
        try soss.pushVector(v);
    }
    test "begin" {
        var empty = try StackStack.init(std.testing.allocator);
        defer empty.deinit();
        try empty.begin([2]i64{ 1, 2 });
        const tossResult = [_]i64{};
        const sossResult = [_]i64{ 1, 2 };
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[0].data.items, sossResult[0..]);
        try empty.toss.push(5);
        try empty.toss.push(6);
        try empty.toss.push(4);
        try empty.begin([2]i64{ 7, 8 });
        const tossResult2 = [_]i64{ 0, 0, 5, 6 };
        const sossResult2 = [_]i64{ 7, 8 };
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult2[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[0].data.items, sossResult[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[1].data.items, sossResult2[0..]);
        try empty.toss.push(9);
        try empty.toss.push(10);
        try empty.toss.push(11);
        try empty.toss.push(12);
        try empty.toss.push(2);
        try empty.begin([2]i64{ 13, 14 });
        const tossResult3 = [_]i64{ 11, 12 };
        const sossResult3 = [_]i64{ 0, 0, 5, 6, 9, 10, 13, 14 };
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult3[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[0].data.items, sossResult[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[1].data.items, sossResult2[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[2].data.items, sossResult3[0..]);
        try empty.toss.push(15);
        try empty.toss.push(16);
        try empty.toss.push(-2);
        try empty.begin([2]i64{ 17, 18 });
        const tossResult4 = [_]i64{};
        const sossResult4 = [_]i64{ 11, 12, 15, 16, 0, 0, 17, 18 };
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult4[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[0].data.items, sossResult[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[1].data.items, sossResult2[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[2].data.items, sossResult3[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[3].data.items, sossResult4[0..]);
    }
    pub fn end(self: *StackStack) !?[2]i64 {
        // Implements the '}' command behaviour which pops a stack from the stack stack
        // returns null if a reflect should happen, a storage offset vector otherwise
        if (self.data.popOrNull()) |soss| {
            const n = self.toss.pop();
            const v = soss.popVector();
            if (n > 0) {
                const nn: usize = @intCast(n);
                try soss.transfert(self.toss, nn);
            } else {
                const nn: usize = @intCast(-n);
                soss.discard(nn);
            }
            self.toss.deinit();
            self.toss = soss;
            return v;
        } else {
            return null;
        }
    }
    test "end" {
        var empty = try StackStack.init(std.testing.allocator);
        defer empty.deinit();
        try empty.toss.push(1);
        try std.testing.expectEqual(empty.end(), null);
        const tossResult = [_]i64{1};
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult[0..]);
        try empty.toss.push(2);
        try empty.toss.push(3);
        try empty.toss.push(4);
        try empty.toss.push(2);
        try empty.begin([2]i64{ 5, 6 });
        try empty.toss.push(7);
        try empty.toss.push(2);
        try std.testing.expectEqual(empty.end(), [2]i64{ 5, 6 });
        const tossResult2 = [_]i64{ 1, 2, 4, 7 };
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult2[0..]);
        try empty.toss.push(1);
        try empty.begin([2]i64{ 8, 9 });
        try empty.toss.push(-2);
        try std.testing.expectEqual(empty.end(), [2]i64{ 8, 9 });
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult[0..]);
    }
    pub fn under(self: *StackStack) !bool {
        if (self.data.items.len == 0) {
            return true;
        }
        const n = self.toss.pop();
        var soss = self.data.items[self.data.items.len - 1];
        if (n > 0) {
            var i: usize = 0;
            while (i < n) : (i += 1) {
                try self.toss.push(soss.pop());
            }
        } else {
            var i: usize = 0;
            while (i < -n) : (i += 1) {
                try soss.push(self.toss.pop());
            }
        }
        return false;
    }
    test "under" {
        var empty = try StackStack.init(std.testing.allocator);
        defer empty.deinit();
        try empty.toss.push(1);
        try std.testing.expectEqual(empty.under(), true);
        const tossResult = [_]i64{1};
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult[0..]);
        try empty.toss.push(2);
        try empty.toss.push(3);
        try empty.toss.push(4);
        try empty.toss.push(5);
        try empty.toss.push(6);
        try empty.toss.push(0);
        try empty.begin([2]i64{ 7, 8 });
        try empty.toss.push(9);
        try empty.toss.push(0);
        try std.testing.expectEqual(empty.under(), false);
        const tossResult2 = [_]i64{9};
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult2[0..]);
        try empty.toss.push(2);
        try std.testing.expectEqual(empty.under(), false);
        const tossResult3 = [_]i64{ 9, 8, 7 };
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult3[0..]);
        try empty.toss.push(-1);
        try std.testing.expectEqual(empty.under(), false);
        const tossResult4 = [_]i64{ 9, 8 };
        const sossResult = [_]i64{ 1, 2, 3, 4, 5, 6, 7 };
        try std.testing.expectEqualSlices(i64, empty.toss.data.items, tossResult4[0..]);
        try std.testing.expectEqualSlices(i64, empty.data.items[0].data.items, sossResult[0..]);
    }
    pub inline fn toss(self: *StackStack) *stack.Stack {
        return self.toss;
    }
};

test "all" {
    std.testing.refAllDecls(@This());
}
