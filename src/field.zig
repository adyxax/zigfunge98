const std = @import("std");

const position = struct { x: i64, y: i64 };

const Line = struct {
    allocator: std.mem.Allocator,
    x: i64 = 0,
    data: std.ArrayList(i64),
    fn blank(l: *Line, x: i64) void {
        const lx: i64 = @intCast(l.len());
        if (x < l.x or x > l.x + lx - 1) { // outside the field
            return;
        } else if (x > l.x and x < l.x + lx - 1) { // just set the value
            l.data.items[@intCast(x - l.x)] = ' ';
        } else if (lx == 1) { // this was the last character on the line
            l.data.items.len = 0;
        } else if (x == l.x) { // we need to remove leading spaces
            var i: usize = 1;
            while (l.data.items[i] == ' ') : (i += 1) {}
            l.x += @intCast(i);
            std.mem.copyForwards(i64, l.data.items[0 .. l.len() - i], l.data.items[i..]);
            l.data.items.len -= i;
        } else { // we need to remove trailing spaces
            var i: usize = l.len() - 1;
            while (l.data.items[i - 1] == ' ') : (i -= 1) {}
            l.data.items.len = i;
        }
    }
    test "blank" {
        var l = try Line.init(std.testing.allocator);
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
    fn deinit(self: *Line) void {
        self.data.deinit();
        self.allocator.destroy(self);
    }
    fn get(l: *Line, x: i64) i64 {
        const ll: i64 = @intCast(l.len());
        if (x >= l.x and x < l.x + ll) return l.data.items[@intCast(x - l.x)];
        return ' ';
    }
    fn init(allocator: std.mem.Allocator) !*Line {
        var l = try allocator.create(Line);
        l.allocator = allocator;
        l.data = std.ArrayList(i64).init(allocator);
        return l;
    }
    inline fn len(l: Line) usize {
        return l.data.items.len;
    }
    fn set(l: *Line, x: i64, v: i64) !void {
        if (l.len() == 0) { // this is en empty line
            l.x = x;
            try l.data.append(v);
            return;
        }
        const lx: i64 = @intCast(l.len());
        if (x >= l.x) {
            if (x < l.x + lx) { // just set the value
                l.data.items[@intCast(x - l.x)] = v;
            } else { // we need to add trailing spaces
                var i: usize = l.len();
                while (i < x - l.x) : (i += 1) {
                    try l.data.append(' ');
                }
                try l.data.append(v);
            }
        } else { // we need to shift right and add leading spaces
            const oldLen = l.len();
            l.data.items.len += @intCast(l.x - x);
            try l.data.ensureUnusedCapacity(l.len());
            std.mem.copyBackwards(i64, l.data.items[@intCast(l.x - x)..], l.data.items[0..oldLen]);
            l.data.items[0] = v;
            var i: usize = 1;
            while (i < l.x - x) : (i += 1) {
                l.data.items[i] = ' ';
            }
            l.x = x;
        }
    }
    test "set" {
        var l = try Line.init(std.testing.allocator);
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
        try std.testing.expectEqual(l.get(-5), ' ');
        try std.testing.expectEqual(l.get(-4), 'e');
        try std.testing.expectEqual(l.get(-3), ' ');
        try std.testing.expectEqual(l.get(2), 'c');
        try std.testing.expectEqual(l.get(3), ' ');
    }
};

pub const Field = struct {
    allocator: std.mem.Allocator,
    x: i64 = 0,
    y: i64 = 0,
    lines: std.ArrayList(*Line),
    lx: usize = 0,
    pub fn blank(f: *Field, x: i64, y: i64) !void {
        const ly = f.lines.items.len;
        if (ly == 0) return error.EmptyFieldError;
        const lly: i64 = @intCast(ly);
        if (y < f.y or y >= f.y + lly) return; // outside the field
        var l = f.lines.items[@intCast(y - f.y)];
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
                f.y += @intCast(i);
                std.mem.copyForwards(*Line, f.lines.items[0 .. f.lines.items.len - i], f.lines.items[i..]);
                f.lines.items.len -= i;
            } else if (y == f.y + lly - 1) { // we need to remove trailing lines
                l.deinit();
                var i: usize = ly - 2;
                while (f.lines.items[i].len() == 0) : (i -= 1) {
                    f.lines.items[i].deinit();
                }
                f.lines.items.len = i + 1;
            }
        }
        const flx: i64 = @intCast(f.lx);
        if (x == f.x or x == f.x + flx - 1) { // recalculate boundaries
            f.x = std.math.maxInt(i64);
            var x2: i64 = std.math.minInt(i64);
            for (f.lines.items) |line| {
                if (line.len() == 0) continue;
                if (f.x > line.x) f.x = line.x;
                const ll: i64 = @intCast(line.len());
                if (x2 < line.x + ll) x2 = line.x + ll;
            }
            f.lx = @intCast(x2 - f.x);
        }
    }
    test "blank" {
        var f = try Field.init(std.testing.allocator);
        defer f.deinit();
        f.lines.items[0].deinit();
        f.lines.clearRetainingCapacity();
        try std.testing.expectEqual(f.blank(1, 0), error.EmptyFieldError);
        var moins2 = try Line.init(std.testing.allocator);
        try moins2.set(-3, 'a');
        var moins1 = try Line.init(std.testing.allocator);
        try moins1.set(6, 'b');
        var zero = try Line.init(std.testing.allocator);
        try zero.set(-4, 'c');
        var un = try Line.init(std.testing.allocator);
        try un.set(-8, 'd');
        var deux = try Line.init(std.testing.allocator);
        try deux.set(12, 'e');
        const initial = [_]*Line{ moins2, moins1, zero, un, deux };
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
            l.*.deinit();
        }
        self.lines.deinit();
        self.allocator.destroy(self);
    }
    pub fn get(f: *Field, x: i64, y: i64) i64 {
        const fl: i64 = @intCast(f.lines.items.len);
        if (y >= f.y and y < f.y + fl) return f.lines.items[@intCast(y - f.y)].get(x);
        return ' ';
    }
    pub fn getSize(f: Field) [4]i64 {
        return [4]i64{ f.x, f.y, @intCast(f.lx), @intCast(f.lines.items.len) };
    }
    fn init(allocator: std.mem.Allocator) !*Field {
        var f = try allocator.create(Field);
        errdefer allocator.destroy(f);
        f.allocator = allocator;
        f.x = undefined;
        f.y = 0;
        f.lines = std.ArrayList(*Line).init(allocator);
        const l = try f.lines.addOne();
        l.* = try Line.init(allocator);
        f.lx = 0;
        return f;
    }
    pub fn init_from_reader(allocator: std.mem.Allocator, reader: anytype) !*Field {
        var f = try Field.init(allocator);
        errdefer f.deinit();
        try f.load(reader);
        return f;
    }
    inline fn isIn(f: *Field, x: i64, y: i64) bool {
        const fl: i64 = @intCast(f.lines.items.len);
        const flx: i64 = @intCast(f.lx);
        return x >= f.x and y >= f.y and x < f.x + flx and y < f.y + fl;
    }
    fn load(f: *Field, reader: anytype) !void {
        if (f.lines.items.len > 1 or f.lx > 0) return error.FIELD_NOT_EMPTY;
        var lastIsCR = false;
        var x: i64 = 0;
        var y: i64 = 0;
        while (true) {
            var buffer: [4096]u8 = undefined;
            const l = try reader.read(buffer[0..]);
            if (l == 0) return;
            var i: usize = 0;
            while (i < l) : (i += 1) {
                if (lastIsCR) {
                    lastIsCR = false;
                    switch (buffer[i]) {
                        '\n' => continue,
                        else => {},
                    }
                }
                switch (buffer[i]) {
                    12 => continue,
                    '\r' => {
                        x = 0;
                        y += 1;
                        lastIsCR = true;
                    },
                    '\n' => {
                        x = 0;
                        y += 1;
                    },
                    else => {
                        try f.set(x, y, buffer[i]);
                        x += 1;
                    },
                }
            }
        }
    }
    test "load" {
        const crData = [_]u8{'v'} ** 4095 ++ "\r\n @";
        var cr = std.io.fixedBufferStream(crData);
        var f = try Field.init(std.testing.allocator);
        defer f.deinit();
        try f.load(cr.reader());
        try std.testing.expectEqual(f.x, 0);
        try std.testing.expectEqual(f.y, 0);
        try std.testing.expectEqual(f.lx, 4095);
        try std.testing.expectEqual(f.lines.items.len, 2);
        try std.testing.expectEqual(f.lines.items[0].data.items[0], 'v');
        try std.testing.expectEqual(f.lines.items[1].x, 1);
        try std.testing.expectEqual(f.lines.items[1].data.items[0], '@');
        var cr2 = std.io.fixedBufferStream("v\r@");
        try std.testing.expectEqual(f.load(cr2.reader()), error.FIELD_NOT_EMPTY);
        var f2 = try Field.init(std.testing.allocator);
        defer f2.deinit();
        try f2.load(cr2.reader());
        try std.testing.expectEqual(f2.x, 0);
        try std.testing.expectEqual(f2.y, 0);
        try std.testing.expectEqual(f2.lx, 1);
        try std.testing.expectEqual(f2.lines.items.len, 2);
        try std.testing.expectEqual(f2.lines.items[0].data.items[0], 'v');
        try std.testing.expectEqual(f2.lines.items[1].x, 0);
        try std.testing.expectEqual(f2.lines.items[1].data.items[0], '@');
    }
    pub fn set(f: *Field, x: i64, y: i64, v: i64) !void {
        if (v == ' ') return f.blank(x, y);
        if (y >= f.y) {
            const fl: i64 = @intCast(f.lines.items.len);
            if (y < f.y + fl) { // the line exists
                try f.lines.items[@intCast(y - f.y)].set(x, v);
            } else { // append lines
                var i: usize = f.lines.items.len;
                while (i < y - f.y) : (i += 1) {
                    try f.lines.append(try Line.init(f.allocator));
                }
                var l = try Line.init(f.allocator);
                try l.set(x, v);
                try f.lines.append(l);
            }
        } else { // preprend lines
            const oldLen = f.lines.items.len;
            const dl: usize = @intCast(f.y - y);
            f.lines.items.len += dl;
            try f.lines.ensureUnusedCapacity(f.lines.items.len);
            std.mem.copyBackwards(*Line, f.lines.items[dl..], f.lines.items[0..oldLen]);
            var l = try Line.init(f.allocator);
            try l.set(x, v);
            f.lines.items[0] = l;
            var i: usize = 1;
            while (i < f.y - y) : (i += 1) {
                f.lines.items[i] = try Line.init(f.allocator);
            }
            f.y = y;
        }
        const flx: i64 = @intCast(f.lx);
        if (x < f.x or x >= f.x + flx) { // recalculate boundaries
            f.x = std.math.maxInt(i64);
            var x2: i64 = std.math.minInt(i64);
            for (f.lines.items) |line| {
                if (line.len() == 0) continue;
                if (f.x > line.x) f.x = line.x;
                const ll: i64 = @intCast(line.len());
                if (x2 < line.x + ll) x2 = line.x + ll;
            }
            f.lx = @intCast(x2 - f.x);
        }
        return;
    }
    test "set" {
        var f = try Field.init(std.testing.allocator);
        defer f.deinit();
        try f.set(0, 0, '0');
        try std.testing.expectEqual(f.lines.items.len, 1);
        try std.testing.expectEqual(f.x, 0);
        try std.testing.expectEqual(f.lx, 1);
        try f.set(8, 2, '2');
        try std.testing.expectEqual(f.lines.items.len, 3);
        try std.testing.expectEqual(f.x, 0);
        try std.testing.expectEqual(f.lx, 9);
        try f.set(-4, 1, '1');
        try std.testing.expectEqual(f.lines.items.len, 3);
        try std.testing.expectEqual(f.x, -4);
        try std.testing.expectEqual(f.lx, 13);
        try std.testing.expectEqual(f.lines.items[1].data.items.len, 1);
        try std.testing.expectEqual(f.lines.items[1].data.items[0], '1');
        try f.set(12, -3, 'a');
        try std.testing.expectEqual(f.lines.items.len, 6);
        try std.testing.expectEqual(f.x, -4);
        try std.testing.expectEqual(f.lx, 17);
        try f.set(-7, -2, 'a');
        try std.testing.expectEqual(f.lines.items.len, 6);
        try std.testing.expectEqual(f.x, -7);
        try std.testing.expectEqual(f.lx, 20);
        try std.testing.expectEqual(f.get(0, 0), '0');
        try std.testing.expectEqual(f.get(8, 2), '2');
        try std.testing.expectEqual(f.get(9, 2), ' ');
    }
    pub fn step(f: *Field, x: i64, y: i64, dx: i64, dy: i64, smartAdvance: bool, jumping: bool) position {
        var a = x + dx;
        var b = y + dy;
        if (!f.isIn(a, b)) {
            // # We are stepping outside, we need to wrap the Lahey-space
            a = x;
            b = y;
            while (true) {
                const c = a - dx;
                const d = b - dy;
                if (!f.isIn(c, d)) break;
                a = c;
                b = d;
            }
        }
        if (smartAdvance) {
            const v = f.get(a, b);
            if (jumping) {
                return f.step(a, b, dx, dy, true, v != ';');
            }
            if (v == ' ') {
                return f.step(a, b, dx, dy, true, false);
            }
            if (v == ';') {
                return f.step(a, b, dx, dy, true, true);
            }
        }
        return .{ .x = a, .y = b };
    }
    test "step" {
        var minimal = std.io.fixedBufferStream("@");
        var f = try Field.init(std.testing.allocator);
        defer f.deinit();
        try f.load(minimal.reader());
        try std.testing.expectEqual(f.step(0, 0, 0, 0, false, false), @as(position, .{ .x = 0, .y = 0 }));
        try std.testing.expectEqual(f.step(0, 0, 1, 0, false, false), @as(position, .{ .x = 0, .y = 0 }));
        var hello = std.io.fixedBufferStream("64+\"!dlroW ,olleH\">:#,_@\n");
        var fHello = try Field.init(std.testing.allocator);
        defer fHello.deinit();
        try fHello.load(hello.reader());
        try std.testing.expectEqual(fHello.step(3, 0, 0, 0, false, false), @as(position, .{ .x = 3, .y = 0 }));
        try std.testing.expectEqual(fHello.step(3, 0, 1, 0, false, false), @as(position, .{ .x = 4, .y = 0 }));
        try std.testing.expectEqual(fHello.step(0, 0, -1, 0, false, false), @as(position, .{ .x = 23, .y = 0 }));
    }
};

test "hello" {
    var hello = std.io.fixedBufferStream("64+\"!dlroW ,olleH\">:#,_@\n");
    var f = try Field.init_from_reader(std.testing.allocator, hello.reader());
    defer f.deinit();
    try std.testing.expectEqual(f.x, 0);
    try std.testing.expectEqual(f.y, 0);
    try std.testing.expectEqual(f.lx, 24);
    try std.testing.expectEqual(f.lines.items.len, 1);
    try std.testing.expectEqual(f.lines.items[0].data.items[0], '6');
}
test "minimal" {
    var minimal = std.io.fixedBufferStream("@");
    var f = try Field.init_from_reader(std.testing.allocator, minimal.reader());
    defer f.deinit();
    try std.testing.expectEqual(f.x, 0);
    try std.testing.expectEqual(f.y, 0);
    try std.testing.expectEqual(f.lx, 1);
    try std.testing.expectEqual(f.lines.items.len, 1);
    try std.testing.expectEqual(f.lines.items[0].data.items[0], '@');
}
