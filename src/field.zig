const std = @import("std");

const Line = struct {
    x: i64 = 0,
    data: std.ArrayList(i64),
    pub fn blank(l: *Line, x: i64) void {
        const lx = @intCast(i64, l.len());
        if (x < l.x or x > l.x + lx) { // outside the field
            return;
        } else if (x > l.x and x < l.x + lx - 1) { // just set the value
            l.data.items[@intCast(usize, x - l.x)] = ' ';
        } else if (lx == 1) { // this was the last character on the line
            l.data.items.len = 0;
        } else if (x == l.x) { // we need to remove leading spaces
            var i: usize = 1;
            while (l.data.items[i] == ' ') : (i += 1) {}
            l.x += @intCast(i64, i);
            std.mem.copy(i64, l.data.items[0 .. l.len() - i], l.data.items[i..]);
            l.data.items.len -= i;
        } else { // we need to remove trailing spaces
            var i: usize = l.len() - 1;
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
        try std.testing.expectEqual(l.len(), 0);
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
    pub inline fn len(l: Line) usize {
        return l.data.items.len;
    }
    pub fn set(l: *Line, x: i64, v: i64) !void {
        if (l.len() == 0) { // this is en empty line
            l.x = x;
            try l.data.append(v);
            return;
        }
        const lx = @intCast(i64, l.len());
        if (x >= l.x and x < l.x + lx) { // just set the value
            l.data.items[@intCast(usize, x - l.x)] = v;
        } else if (x < l.x) { // we need to shift right and add leading spaces
            const oldLen = l.len();
            l.data.items.len += @intCast(usize, l.x - x);
            try l.data.ensureUnusedCapacity(l.len());
            std.mem.copyBackwards(i64, l.data.items[@intCast(usize, l.x - x)..], l.data.items[0..oldLen]);
            l.data.items[0] = v;
            var i: usize = 1;
            while (i < @intCast(usize, l.x - x)) : (i += 1) {
                l.data.items[i] = ' ';
            }
            l.x = x;
        } else { // we need to add trailing spaces
            var i: usize = l.len();
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
    pub fn blank(f: *Field, x: i64, y: i64) !void {
        const ly = @intCast(i64, f.lines.items.len);
        if (ly == 0) return error.EmptyFieldError;
        if (y < f.y or y > f.y + ly) return; // outside the field
        var l = &f.lines.items[@intCast(usize, y - f.y)];
        if (l.len() == 0) return; // the line is already empty
        l.blank(x);
        if (l.len() == 0) {
            if (ly == 1) {
                return error.EmptyFieldError;
            } else if (y == f.y) { // we need to remove leading lines
                l.deinit();
                var i: usize = 1;
                while (f.lines.items[i].len() == 0) : (i += 1) {
                    f.lines.items[i].deinit();
                }
                f.y += @intCast(i64, i);
                std.mem.copy(Line, f.lines.items[0 .. f.lines.items.len - i], f.lines.items[i..]);
                f.lines.items.len -= i;
            } else if (y == f.y + ly - 1) { // we need to remove trailing lines
                l.deinit();
                var i: usize = @intCast(usize, ly) - 2;
                while (f.lines.items[i].len() == 0) : (i -= 1) {
                    f.lines.items[i].deinit();
                }
                f.lines.items.len = i + 1;
            }
        }
        if (x == f.x or x == f.x + @intCast(i64, f.lx) - 1) { // recalculate boundaries
            f.x = std.math.maxInt(i64);
            var x2: i64 = std.math.minInt(i64);
            for (f.lines.items) |line| {
                if (line.len() == 0) continue;
                if (f.x > line.x) f.x = line.x;
                if (x2 < line.x + @intCast(i64, line.len())) x2 = line.x + @intCast(i64, line.len());
            }
            f.lx = @intCast(usize, x2 - f.x);
        }
    }
    test "blank" {
        var f = try Field.init(std.testing.allocator);
        defer f.deinit();
        try std.testing.expectEqual(f.blank(1, 0), error.EmptyFieldError);
        var moins2 = Line.init(std.testing.allocator);
        try moins2.set(-3, 'a');
        var moins1 = Line.init(std.testing.allocator);
        try moins1.set(6, 'b');
        var zero = Line.init(std.testing.allocator);
        try zero.set(-4, 'c');
        var un = Line.init(std.testing.allocator);
        try un.set(-8, 'd');
        var deux = Line.init(std.testing.allocator);
        try deux.set(12, 'e');
        const initial = [_]Line{ moins2, moins1, zero, un, deux };
        try f.lines.appendSlice(initial[0..]);
        f.x = -8;
        f.lx = 21;
        f.y = -2;
        try f.blank(6, -1);
        try std.testing.expectEqual(f.x, -8);
        try std.testing.expectEqual(f.lx, 21);
        try std.testing.expectEqual(f.y, -2);
        try std.testing.expectEqual(f.lines.items.len, 5);
        try std.testing.expectEqual(f.lines.items[1].len(), 0);
        try f.blank(-3, -2);
        try std.testing.expectEqual(f.x, -8);
        try std.testing.expectEqual(f.lx, 21);
        try std.testing.expectEqual(f.y, 0);
        try std.testing.expectEqual(f.lines.items.len, 3);
        try f.blank(-8, 1);
        try std.testing.expectEqual(f.x, -4);
        try std.testing.expectEqual(f.lx, 17);
        try std.testing.expectEqual(f.y, 0);
        try std.testing.expectEqual(f.lines.items.len, 3);
        try std.testing.expectEqual(f.lines.items[1].len(), 0);
        try f.blank(12, 2);
        try std.testing.expectEqual(f.x, -4);
        try std.testing.expectEqual(f.lx, 1);
        try std.testing.expectEqual(f.y, 0);
        try std.testing.expectEqual(f.lines.items.len, 1);
        try std.testing.expectEqual(f.blank(-4, 0), error.EmptyFieldError);
    }
    pub fn deinit(self: *Field) void {
        for (self.lines.items) |*l| {
            l.deinit();
        }
        self.lines.deinit();
    }
    pub fn init(allocator: std.mem.Allocator) !Field {
        var lines = std.ArrayList(Line).init(allocator);
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
