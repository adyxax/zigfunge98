const std = @import("std");
const io = @import("io.zig");
const field = @import("field.zig");
const stackStack = @import("stackStack.zig");

const vector = std.meta.Vector(2, i64);

const pointerErrorType = error{ EmptyFieldError, IOError, NotImplemented, OutOfMemory };

const pointerReturn = struct {
    code: ?i64 = null,
};

const PointerInfo = struct { x: i64, y: i64, dx: i64, dy: i64 };

pub const Pointer = struct {
    allocator: std.mem.Allocator,
    field: *field.Field,
    x: i64 = 0, // The position
    y: i64 = 0,
    dx: i64 = 1, // The traveling delta
    dy: i64 = 0,
    sox: i64 = 0, // The storage offset
    soy: i64 = 0,
    stringMode: bool = false, // string mode flags
    lastCharWasSpace: bool = false,
    ss: *stackStack.StackStack,
    env: []const [*:0]const u8,
    argv: []const []const u8,
    rand: std.rand.DefaultPrng,
    timestamp: ?i64,

    pub fn deinit(self: *Pointer) void {
        self.ss.deinit();
        self.allocator.destroy(self);
    }
    fn eval(p: *Pointer, ioContext: anytype, c: i64) pointerErrorType!?pointerReturn {
        // Returns non nil if the pointer terminated, and a return code if
        // the program should terminate completely
        switch (c) {
            '@' => return pointerReturn{},
            'z' => {},
            '#' => {
                p.step(false);
            },
            'j' => {
                const n = p.ss.toss.pop();
                var j: usize = 0;
                if (n > 0) {
                    while (j < n) : (j += 1) {
                        p.step(false);
                    }
                } else {
                    p.reverse();
                    while (j < -n) : (j += 1) {
                        p.step(false);
                    }
                    p.reverse();
                }
            },
            'q' => return pointerReturn{ .code = p.ss.toss.pop() },
            'k' => {
                const x = p.x;
                const y = p.y;
                const n = p.ss.toss.pop();
                var v = p.stepAndGet(false);
                var jumpingMode = false;
                while (jumpingMode or v == ' ' or v == ';') : (v = p.stepAndGet(false)) {
                    if (v == ';') jumpingMode = !jumpingMode;
                }
                if (n > 0) {
                    p.x = x;
                    p.y = y;
                    if (v != ' ' and v != ';') {
                        if (v == 'q' or v == '@') return try p.eval(ioContext, v);
                        var i: usize = 0;
                        while (i < n) : (i += 1) _ = try p.eval(ioContext, v);
                    }
                }
            },
            '!' => {
                if (p.ss.toss.pop() == 0) {
                    try p.ss.toss.push(1);
                } else {
                    try p.ss.toss.push(0);
                }
            },
            '`' => {
                const v = p.ss.toss.popVector();
                if (v[0] > v[1]) {
                    try p.ss.toss.push(1);
                } else {
                    try p.ss.toss.push(0);
                }
            },
            '_' => {
                if (p.ss.toss.pop() == 0) {
                    p.dx = 1;
                } else {
                    p.dx = -1;
                }
                p.dy = 0;
            },
            '|' => {
                p.dx = 0;
                if (p.ss.toss.pop() == 0) {
                    p.dy = 1;
                } else {
                    p.dy = -1;
                }
            },
            'w' => {
                const v = p.ss.toss.popVector();
                const dx = p.dx;
                if (v[0] < v[1]) {
                    p.dx = p.dy;
                    p.dy = -dx;
                } else if (v[0] > v[1]) {
                    p.dx = -p.dy;
                    p.dy = dx;
                }
            },
            '+' => {
                const v = p.ss.toss.popVector();
                try p.ss.toss.push(v[0] + v[1]);
            },
            '*' => {
                const v = p.ss.toss.popVector();
                try p.ss.toss.push(v[0] * v[1]);
            },
            '-' => {
                const v = p.ss.toss.popVector();
                try p.ss.toss.push(v[0] - v[1]);
            },
            '/' => {
                const v = p.ss.toss.popVector();
                if (v[1] == 0) {
                    try p.ss.toss.push(0);
                } else {
                    try p.ss.toss.push(@divFloor(v[0], v[1]));
                }
            },
            '%' => {
                const v = p.ss.toss.popVector();
                if (v[1] == 0) {
                    try p.ss.toss.push(0);
                } else {
                    try p.ss.toss.push(@mod(v[0], v[1]));
                }
            },
            '"' => p.stringMode = true,
            '\'' => {
                try p.ss.toss.push(p.stepAndGet(false));
            },
            's' => {
                p.step(false);
                try p.field.set(p.x, p.y, p.ss.toss.pop());
            },
            '$' => _ = p.ss.toss.pop(),
            ':' => try p.ss.toss.duplicate(),
            '\\' => try p.ss.toss.swap(),
            'n' => p.ss.toss.clear(),
            '{' => {
                p.ss.begin([2]i64{ p.sox, p.soy }) catch {
                    p.reverse();
                    return null;
                };
                p.sox = p.x + p.dx;
                p.soy = p.y + p.dy;
            },
            '}' => {
                const v = p.ss.end() catch null;
                if (v) |so| {
                    p.sox = so[0];
                    p.soy = so[1];
                } else {
                    p.reverse();
                }
            },
            'u' => {
                if (p.ss.under() catch true) {
                    p.reverse();
                }
            },
            'g' => {
                const v = p.ss.toss.popVector();
                try p.ss.toss.push(p.field.get(v[0] + p.sox, v[1] + p.soy));
            },
            'p' => {
                const v = p.ss.toss.popVector();
                const n = p.ss.toss.pop();
                try p.field.set(v[0] + p.sox, v[1] + p.soy, n);
            },
            '.' => ioContext.decimalOutput(p.ss.toss.pop()) catch {
                p.reverse();
                return null;
            },
            ',' => ioContext.characterOutput(p.ss.toss.pop()) catch p.reverse(),
            '&' => {
                const n = ioContext.decimalInput() catch {
                    p.reverse();
                    return null;
                };
                p.ss.toss.push(n) catch p.reverse();
            },
            '~' => {
                const n = ioContext.characterInput() catch {
                    p.reverse();
                    return null;
                };
                p.ss.toss.push(n) catch p.reverse();
            },
            'y' => {
                const n = p.ss.toss.pop();
                const fieldSize = p.field.getSize();
                const height = p.ss.toss.data.items.len;
                // 20
                var i: usize = 0;
                while (i < p.env.len) : (i += 1) {
                    var j: usize = 0;
                    // env is a null terminated string, calculate its len
                    while (p.env[i][j] != 0) : (j += 1) {}
                    if (j == 0) {
                        break;
                    }
                    try p.ss.toss.push(0);
                    j -= 1;
                    while (true) : (j -= 1) {
                        try p.ss.toss.push(p.env[i][j]);
                        if (j == 0) break;
                    }
                }
                // 19
                try p.ss.toss.pushVector([2]i64{ 0, 0 });
                i = p.argv.len - 1;
                while (i >= 0) : (i -= 1) {
                    try p.ss.toss.push(0);
                    var j: usize = p.argv[i].len - 1;
                    while (true) : (j -= 1) {
                        try p.ss.toss.push(p.argv[i][j]);
                        if (j == 0) break;
                    }
                    if (i == 0) break;
                }
                // 18
                i = 0;
                while (i < p.ss.data.items.len) : (i += 1) {
                    try p.ss.toss.push(@intCast(p.ss.data.items[i].data.items.len));
                }
                try p.ss.toss.push(@intCast(height));
                // 17
                try p.ss.toss.push(@intCast(p.ss.data.items.len + 1));
                // 16
                const ts = if (p.timestamp) |v| v else std.time.timestamp();
                const now = std.time.epoch.EpochSeconds{ .secs = @intCast(ts) };
                const epochDay = now.getEpochDay();
                const daySeconds = now.getDaySeconds();
                const hours: i64 = @intCast(daySeconds.getHoursIntoDay());
                const minutes: i64 = @intCast(daySeconds.getMinutesIntoHour());
                const seconds: i64 = @intCast(daySeconds.getSecondsIntoMinute());
                try p.ss.toss.push(hours * 256 * 256 + minutes * 256 + seconds);
                // 15
                const yearAndDay = epochDay.calculateYearDay();
                const year: i64 = @intCast(yearAndDay.year);
                const monthAndDay = yearAndDay.calculateMonthDay();
                const month: i64 = @intCast(monthAndDay.month.numeric());
                try p.ss.toss.push((year - 1900) * 256 * 256 + month * 256 + monthAndDay.day_index);
                // 14
                try p.ss.toss.pushVector([2]i64{ fieldSize[2] - 1, fieldSize[3] - 1 });
                // 13
                try p.ss.toss.pushVector([2]i64{ fieldSize[0], fieldSize[1] });
                // 12
                try p.ss.toss.pushVector([2]i64{ p.sox, p.soy });
                // 11
                try p.ss.toss.pushVector([2]i64{ p.dx, p.dy });
                // 10
                try p.ss.toss.pushVector([2]i64{ p.x, p.y });
                // 9
                try p.ss.toss.push(0);
                // 8
                try p.ss.toss.push(0); // TODO update when implementing =
                // 7
                try p.ss.toss.push(2);
                // 6
                try p.ss.toss.push('/');
                // 5
                try p.ss.toss.push(0); // TODO update when implementing =
                // 4
                try p.ss.toss.push(1);
                // 3
                try p.ss.toss.push(1048578);
                // 2
                try p.ss.toss.push(@sizeOf(i64));
                // 1
                try p.ss.toss.push(0b00000); // TODO update when implementing t, i, o and =
                if (n > 0) {
                    try p.ss.toss.yCommandPick(@intCast(n), height);
                }
            },
            '(' => {
                const n = p.ss.toss.pop();
                var v: i64 = 0;
                var i: usize = 0;
                while (i < n) : (i += 1) {
                    v = v * 256 + p.ss.toss.pop();
                }
                p.reverse(); // no fingerprints supported for now
            },
            ')' => {
                const n = p.ss.toss.pop();
                var v: i64 = 0;
                var i: usize = 0;
                while (i < n) : (i += 1) {
                    v = v * 256 + p.ss.toss.pop();
                }
                p.reverse(); // no fingerprints supported for now
            },
            'i' => return error.NotImplemented,
            'o' => return error.NotImplemented,
            '=' => return error.NotImplemented,
            't' => return error.NotImplemented,
            else => if (!p.redirect(c)) {
                if (c >= '0' and c <= '9') {
                    try p.ss.toss.push(c - '0');
                } else if (c >= 'a' and c <= 'f') {
                    try p.ss.toss.push(c - 'a' + 10);
                } else {
                    p.reverse();
                }
            },
        }
        return null;
    }
    pub fn exec(self: *Pointer, ioContext: anytype) !?pointerReturn {
        // Advances to the next instruction of the field and executes it
        // Returns non nil if the pointer terminated, and a return code if
        // the program should terminate completely
        var result: ?pointerReturn = null;
        var c = self.field.get(self.x, self.y);
        if (self.stringMode) {
            if (self.lastCharWasSpace) {
                while (c == ' ') {
                    c = self.stepAndGet(false);
                }
                self.lastCharWasSpace = false;
            }
            if (c == '"') {
                self.stringMode = false;
            } else {
                if (c == ' ') self.lastCharWasSpace = true;
                try self.ss.toss.push(c);
            }
        } else {
            var jumpingMode = false;
            while (jumpingMode or c == ' ' or c == ';') {
                if (c == ';') jumpingMode = !jumpingMode;
                c = self.stepAndGet(false);
            }
            result = try self.eval(ioContext, c);
        }
        self.step(!self.stringMode);
        return result;
    }
    pub fn init(allocator: std.mem.Allocator, f: *field.Field, timestamp: ?i64, argv: []const []const u8, env: []const [*:0]const u8) !*Pointer {
        var p = try allocator.create(Pointer);
        errdefer allocator.destroy(p);
        p.allocator = allocator;
        p.field = f;
        p.ss = try stackStack.StackStack.init(allocator);
        p.argv = argv;
        p.env = env;
        p.x = 0;
        p.y = 0;
        p.dx = 1;
        p.dy = 0;
        p.sox = 0;
        p.soy = 0;
        p.stringMode = false;
        p.lastCharWasSpace = false;
        // Initializing the random number generator
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        p.rand = std.rand.DefaultPrng.init(seed);
        p.timestamp = timestamp;
        return p;
    }
    inline fn redirect(p: *Pointer, c: i64) bool {
        switch (c) {
            '^' => {
                p.dx = 0;
                p.dy = -1;
            },
            '>' => {
                p.dx = 1;
                p.dy = 0;
            },
            'v' => {
                p.dx = 0;
                p.dy = 1;
            },
            '<' => {
                p.dx = -1;
                p.dy = 0;
            },
            '?' => {
                const directions = [_]i8{ 0, -1, 1, 0, 0, 1, -1, 0 };
                const r = 2 * p.rand.random().intRangeAtMost(u8, 0, 3);
                p.dx = directions[r];
                p.dy = directions[r + 1];
            },
            '[' => {
                const dx = p.dx;
                p.dx = p.dy;
                p.dy = -dx;
            },
            ']' => {
                const dx = p.dx;
                p.dx = -p.dy;
                p.dy = dx;
            },
            'r' => p.reverse(),
            'x' => {
                const v = p.ss.toss.popVector();
                p.dx = v[0];
                p.dy = v[1];
            },
            else => return false,
        }
        return true;
    }
    inline fn reverse(p: *Pointer) void {
        p.dx = -p.dx;
        p.dy = -p.dy;
    }
    inline fn step(self: *Pointer, smartAdvance: bool) void {
        const v = self.field.step(self.x, self.y, self.dx, self.dy, smartAdvance, false);
        self.x = v.x;
        self.y = v.y;
    }
    inline fn stepAndGet(self: *Pointer, smartAdvance: bool) i64 {
        self.step(smartAdvance);
        return self.field.get(self.x, self.y);
    }
};

const testTimestamp: i64 = 1660681247;

test "minimal" {
    var minimal = std.io.fixedBufferStream("@");
    var f = try field.Field.init_from_reader(std.testing.allocator, minimal.reader());
    defer f.deinit();
    const argv = [_][]const u8{"minimal"};
    const env = [_][*:0]const u8{"ENV=TEST"};
    var p = try Pointer.init(std.testing.allocator, f, testTimestamp, argv[0..], env[0..]);
    defer p.deinit();
    var ioContext = io.context(std.io.getStdIn().reader(), std.io.getStdOut().writer());
    try std.testing.expectEqual(p.exec(&ioContext), pointerReturn{});
}
test "almost minimal" {
    var minimal = std.io.fixedBufferStream(" @");
    var f = try field.Field.init_from_reader(std.testing.allocator, minimal.reader());
    defer f.deinit();
    const argv = [_][]const u8{"minimal"};
    const env = [_][*:0]const u8{"ENV=TEST"};
    var p = try Pointer.init(std.testing.allocator, f, testTimestamp, argv[0..], env[0..]);
    defer p.deinit();
    var ioContext = io.context(std.io.getStdIn().reader(), std.io.getStdOut().writer());
    try std.testing.expectEqual(p.exec(&ioContext), pointerReturn{});
}
