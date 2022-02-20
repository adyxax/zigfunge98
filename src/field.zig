const std = @import("std");

const Line = struct {
    x: i64 = 0,
    data: std.ArrayList(i64),
    pub fn blank(l: *Line, x: i64) void {
        const lx = @intCast(i64, l.data.items.len);
        if (x > l.x and x < l.x + lx - 1) { // just set the value
            l.data.items[@intCast(usize, x - l.x)] = ' ';
        } else if (lx == 1) { // this was the last character on the line
            l.data.items.len = 0;
        } else if (x == l.x) { // we need to remove leading spaces
            var i: usize = 1;
            while (l.data.items[i] == ' ') : (i += 1) {}
            l.x += @intCast(i64, i);
            std.mem.copy(i64, l.data.items[0 .. l.data.items.len - i], l.data.items[i..]);
            l.data.items.len -= i;
        } else if (x == l.x + lx - 1) { // we need to remove trailing spaces
            var i: usize = l.data.items.len - 1;
            while (l.data.items[i - 1] == ' ') : (i -= 1) {}
            l.data.items.len = i;
        }
    }
    test "blank" {
        var l = Line.init(std.testing.allocator);
        defer l.deinit();
        const initial = [_]i64{ 'b', 'a', '@', 'c', 'd', 'e', 'f' };
        try l.data.appendSlice(initial[0..]);
        l.x = -2;
        l.blank(-3);
        try std.testing.expectEqualSlices(i64, l.data.items, initial[0..]);
        l.blank(8);
        try std.testing.expectEqualSlices(i64, l.data.items, initial[0..]);
        l.blank(0);
        const zero = [_]i64{ 'b', 'a', ' ', 'c', 'd', 'e', 'f' };
        try std.testing.expectEqual(l.x, -2);
        try std.testing.expectEqualSlices(i64, l.data.items, zero[0..]);
        l.blank(-2);
        const moins2 = [_]i64{ 'a', ' ', 'c', 'd', 'e', 'f' };
        try std.testing.expectEqual(l.x, -1);
        try std.testing.expectEqualSlices(i64, l.data.items, moins2[0..]);
        l.blank(-1);
        const moins1 = [_]i64{ 'c', 'd', 'e', 'f' };
        try std.testing.expectEqual(l.x, 1);
        try std.testing.expectEqualSlices(i64, l.data.items, moins1[0..]);
        l.blank(4);
        const plus4 = [_]i64{ 'c', 'd', 'e' };
        try std.testing.expectEqual(l.x, 1);
        try std.testing.expectEqualSlices(i64, l.data.items, plus4[0..]);
        l.blank(2);
        const plus2 = [_]i64{ 'c', ' ', 'e' };
        try std.testing.expectEqual(l.x, 1);
        try std.testing.expectEqualSlices(i64, l.data.items, plus2[0..]);
        l.blank(3);
        const plus3 = [_]i64{'c'};
        try std.testing.expectEqual(l.x, 1);
        try std.testing.expectEqualSlices(i64, l.data.items, plus3[0..]);
        l.blank(1);
        try std.testing.expectEqual(l.data.items.len, 0);
    }
    pub fn deinit(self: *Line) void {
        self.data.deinit();
    }
    pub fn init(allocator: std.mem.Allocator) Line {
        const c = std.ArrayList(i64).init(allocator);
        return Line{
            .data = c,
        };
    }
    pub fn set(l: *Line, x: i64, v: i64) !void {
        if (l.data.items.len == 0) { // this is en empty line
            l.x = x;
            try l.data.append(v);
            return;
        }
        const lx = @intCast(i64, l.data.items.len);
        if (x >= l.x and x < l.x + lx) { // just set the value
            l.data.items[@intCast(usize, x - l.x)] = v;
        } else if (x < l.x) { // we need to shift right and add leading spaces
            const oldLen = l.data.items.len;
            l.data.items.len += @intCast(usize, l.x - x);
            try l.data.ensureUnusedCapacity(l.data.items.len);
            std.mem.copyBackwards(i64, l.data.items[@intCast(usize, l.x - x)..], l.data.items[0..oldLen]);
            l.data.items[0] = v;
            var i: usize = 1;
            while (i < @intCast(usize, l.x - x)) : (i += 1) {
                l.data.items[i] = ' ';
            }
            l.x = x;
        } else { // we need to add trailing spaces
            var i: usize = l.data.items.len;
            while (i < x - l.x) : (i += 1) {
                try l.data.append(' ');
            }
            try l.data.append(v);
        }
    }
    test "set" {
        var l = Line.init(std.testing.allocator);
        defer l.deinit();
        try l.set(-1, '@');
        const zero = [_]i64{'@'};
        try std.testing.expectEqual(l.x, -1);
        try std.testing.expectEqualSlices(i64, l.data.items, zero[0..]);
        try l.set(-1, 'a');
        const a = [_]i64{'a'};
        try std.testing.expectEqual(l.x, -1);
        try std.testing.expectEqualSlices(i64, l.data.items, a[0..]);
        try l.set(0, 'b');
        const b = [_]i64{ 'a', 'b' };
        try std.testing.expectEqual(l.x, -1);
        try std.testing.expectEqualSlices(i64, l.data.items, b[0..]);
        try l.set(2, 'c');
        const c = [_]i64{ 'a', 'b', ' ', 'c' };
        try std.testing.expectEqual(l.x, -1);
        try std.testing.expectEqualSlices(i64, l.data.items, c[0..]);
        try l.set(-2, 'd');
        const d = [_]i64{ 'd', 'a', 'b', ' ', 'c' };
        try std.testing.expectEqual(l.x, -2);
        try std.testing.expectEqualSlices(i64, l.data.items, d[0..]);
        try l.set(-4, 'e');
        const e = [_]i64{ 'e', ' ', 'd', 'a', 'b', ' ', 'c' };
        try std.testing.expectEqual(l.x, -4);
        try std.testing.expectEqualSlices(i64, l.data.items, e[0..]);
    }
};

const Field = struct {
    allocator: std.mem.Allocator,
    x: i64 = 0,
    y: i64 = 0,
    lines: std.ArrayList(Line),
    lx: usize = 0,
    pub fn blank(f: *Field, x: i64, y: i64) void {
        const ly = @intCast(i64, f.lines.items.len);
        if (y < f.y or y > f.y + ly) return; // outside the field
        var l = &f.lines.items[@intCast(usize, y - f.y)];
        if (l.data.items.len == 0) return; // the line is already empty
        l.blank(x);
        return; // TODO
    }
    pub fn deinit(self: *Field) void {
        for (self.lines.items) |*l| {
            l.deinit();
        }
        self.lines.deinit();
    }
    pub fn init(allocator: std.mem.Allocator) !Field {
        var lines = std.ArrayList(Line).init(allocator);
        var line = try lines.addOne();
        line.* = Line.init(allocator);
        try line.set(0, '@');
        return Field{
            .allocator = allocator,
            .lines = lines,
        };
    }
    //pub fn load(self: *Field, reader: std.io.Reader) {
    //    var br = std.io.bufferedReader(reader);
    //    var leadingSpaces:u64 = 0;
    //    var trailingSpaces:u64 = 0;
    //    var lastReadIsCR: bool = false;
    //}
    //pub fn set(self: *Field, x: i64, y: i64, v: i64) !void {
    //    if (v == ' ') return self.blank(x, y);
    //    return; // TODO
    //}

    //test "minimal" {
    //    var f = try Field.init(std.testing.allocator);
    //    defer f.deinit();
    //    f.blank(0, 0);
    //}
};

test "all" {
    std.testing.refAllDecls(@This());
}
