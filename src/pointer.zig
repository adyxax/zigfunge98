const std = @import("std");
const io = @import("io.zig");
const field = @import("field.zig");
const stackStack = @import("stackStack.zig");

const vector = std.meta.Vector(2, i64);

const pointerErrorType = error{ EmptyFieldError, IOError, NotImplemented, OutOfMemory };

const pointerReturn = struct {
    code: ?i64 = null,
};

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
    argv: []const []const u8,
    rand: *std.rand.Random,

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
            '#' => p.step(),
            'j' => {
                var n = p.ss.toss.pop();
                var j: usize = 0;
                if (n > 0) {
                    while (j < n) : (j += 1) {
                        p.step();
                    }
                } else {
                    p.reverse();
                    while (j < -n) : (j += 1) {
                        p.step();
                    }
                    p.reverse();
                }
            },
            'q' => return pointerReturn{ .code = p.ss.toss.pop() },
            'k' => {
                const x = p.x;
                const y = p.y;
                const n = p.ss.toss.pop();
                var v = p.stepAndGet();
                var jumpingMode = false;
                while (jumpingMode or v == ' ' or v == ';') : (v = p.stepAndGet()) {
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
            '\'' => try p.ss.toss.push(p.stepAndGet()),
            's' => {
                p.step();
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
            // TODO
            'u' => return error.NotImplemented,
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
            'y' => return error.NotImplemented,
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
                    c = self.stepAndGet();
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
                c = self.stepAndGet();
            }
            result = try self.eval(ioContext, c);
        }
        self.step();
        return result;
    }
    pub fn init(allocator: std.mem.Allocator, f: *field.Field, argv: []const []const u8) !*Pointer {
        var p = try allocator.create(Pointer);
        errdefer allocator.destroy(p);
        p.allocator = allocator;
        p.field = f;
        p.ss = try stackStack.StackStack.init(allocator);
        p.argv = argv;
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
        try std.os.getrandom(std.mem.asBytes(&seed));
        var prng = std.rand.DefaultPrng.init(seed);
        p.rand = &prng.random();
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
                const r = 2 * p.rand.intRangeAtMost(u8, 0, 3);
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
    inline fn step(self: *Pointer) void {
        const v = self.field.step(self.x, self.y, self.dx, self.dy);
        self.x = v.x;
        self.y = v.y;
    }
    inline fn stepAndGet(self: *Pointer) i64 {
        self.step();
        return self.field.get(self.x, self.y);
    }
};

test "all" {
    std.testing.refAllDecls(@This());
}
test "minimal" {
    const minimal = std.io.fixedBufferStream("@").reader();
    var f = try field.Field.init_from_reader(std.testing.allocator, minimal);
    defer f.deinit();
    const argv = [_][]const u8{"minimal"};
    var p = try Pointer.init(std.testing.allocator, f, argv[0..]);
    defer p.deinit();
    var ioContext = io.context(std.io.getStdIn().reader(), std.io.getStdOut().writer());
    try std.testing.expectEqual(p.exec(&ioContext), pointerReturn{});
}
test "almost minimal" {
    const minimal = std.io.fixedBufferStream(" @").reader();
    var f = try field.Field.init_from_reader(std.testing.allocator, minimal);
    defer f.deinit();
    const argv = [_][]const u8{"minimal"};
    var p = try Pointer.init(std.testing.allocator, f, argv[0..]);
    defer p.deinit();
    var ioContext = io.context(std.io.getStdIn().reader(), std.io.getStdOut().writer());
    try std.testing.expectEqual(p.exec(&ioContext), pointerReturn{});
}
