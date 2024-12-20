const std = @import("std");
const interpreter = @import("interpreter.zig");
const io = @import("io.zig");

const spoon = @import("spoon");
var term: spoon.Term = undefined;
var args: [][:0]u8 = undefined;
var intp: *interpreter.Interpreter = undefined;

pub fn main() anyerror!void {
    //--- befunge initialization ----------------------------------------------
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    if (args.len < 2) {
        std.debug.print("Usage: {s} <b98_file_to_run>\n", .{args[0]});
        std.posix.exit(1);
    }

    var file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    const env: []const [*:0]const u8 = std.os.environ;
    intp = try interpreter.Interpreter.init(gpa, file.reader(), null, args, env[0..]);
    defer intp.deinit();

    var ioContext = io.context(std.io.getStdIn().reader(), std.io.getStdOut().writer()); // TODO io functions for tui

    //--- Term initialization -------------------------------------------------
    try term.init(.{});
    defer term.deinit() catch {};

    try std.posix.sigaction(std.posix.SIG.WINCH, &std.posix.Sigaction{
        .handler = .{ .handler = handleSigWinch },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    }, null);

    var fds: [1]std.posix.pollfd = undefined;
    if (term.tty) |tty| {
        fds[0] = .{
            .fd = tty,
            .events = std.posix.POLL.IN,
            .revents = undefined,
        };
    }
    try term.uncook(.{});
    defer term.cook() catch {};

    //--- Main loop -----------------------------------------------------------
    try term.fetchSize();
    try term.setWindowTitle("zigfunge98-tui", .{});
    try render();

    var buf: [16]u8 = undefined;
    var done = false;
    while (!done) {
        _ = try std.posix.poll(&fds, -1);

        const read = try term.readInput(&buf);
        var it = spoon.inputParser(buf[0..read]);
        while (it.next()) |in| {
            if (in.eqlDescription("escape") or in.eqlDescription("q")) {
                done = true;
                break;
            } else if (in.eqlDescription("s")) {
                if (try intp.step(&ioContext)) |code| {
                    try term.cook();
                    term.deinit() catch {};
                    intp.deinit();
                    file.close();
                    std.process.argsFree(gpa, args);
                    std.posix.exit(@intCast(code));
                }
                try render();
            }
        }
    }
}

fn handleSigWinch(_: c_int) callconv(.C) void {
    term.fetchSize() catch {};
    render() catch {};
}

fn render() !void {
    var rc = try term.getRenderContext();
    defer rc.done() catch {};

    try rc.clear();

    if (term.width < 80 or term.height < 24) {
        try rc.setAttribute(.{ .fg = .red, .bold = true });
        try rc.writeAllWrapping("Terminal too small!");
        return;
    }

    try rc.moveCursorTo(0, 0);
    var filename = rc.restrictedPaddingWriter(term.width);
    try filename.writer().print("{s} | steps:{d}", .{ args[1], 0 });

    try rc.moveCursorTo(2, 0);
    try rc.setAttribute(.{ .fg = .green, .reverse = true });
    var stack = rc.restrictedPaddingWriter(16);
    try stack.writer().writeAll("---- Stack ----");
    try rc.setAttribute(.{ .fg = .green, .reverse = false });
    var n: usize = 0;
    while (n < intp.pointer.ss.toss.data.items.len) : (n += 1) {
        try rc.moveCursorTo(3 + n, 0);
        var s = rc.restrictedPaddingWriter(16);
        const v = intp.pointer.ss.toss.data.items[n];
        if (v >= 32 and v < 127) {
            const tv: u8 = @intCast(v);
            try s.writer().print("{c} - {d}", .{ tv, v });
        } else {
            try s.writer().print("{d}", .{v});
        }
    }

    try rc.moveCursorTo(2, 18);
    try rc.setAttribute(.{ .fg = .blue, .reverse = true });
    var fieldTitle = rc.restrictedPaddingWriter(term.width - 17);
    const sizei = intp.field.getSize();
    const size = [4]usize{ @intCast(sizei[0]), @intCast(sizei[1]), @intCast(sizei[2]), @intCast(sizei[3]) };
    try fieldTitle.writer().print("Funge field | top left corner:({d},{d}) size:{d}x{d}", .{ size[0], size[1], size[2], size[3] });
    try fieldTitle.pad();
    try rc.setAttribute(.{ .fg = .blue, .reverse = false });
    var y: usize = 0; // TODO negative lines
    while (y < @min(size[3], term.height - 3)) : (y += 1) {
        var field = rc.restrictedPaddingWriter(term.width - 17);
        const line = intp.field.lines.items[y];
        var x: usize = 0;
        if (line.x >= 0) {
            const lx: usize = @intCast(line.x);
            try rc.moveCursorTo(y + 3, 18 + lx);
        } else {
            try rc.moveCursorTo(y + 3, 18); // TODO negative columns
        }
        while (x < @min(line.data.items.len, term.width - 18)) : (x += 1) {
            var reset = false;
            const xx: i64 = @intCast(x);
            if (xx + line.x == intp.pointer.x and y == intp.pointer.y) { // TODO negatives
                try rc.setAttribute(.{ .fg = .red, .reverse = true });
                reset = true;
            }
            if (line.data.items[x] >= 32 and line.data.items[x] < 127) {
                const v = line.data.items[x];
                var vv: u8 = '?';
                if (v >= 32 and v < 127) {
                    vv = @intCast(v);
                }
                try field.writer().print("{c}", .{vv});
            } else {
                try field.writer().writeAll("®");
            }
            if (reset) {
                try rc.setAttribute(.{ .fg = .blue, .reverse = false });
            }
        }
    }
}
