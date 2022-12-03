const std = @import("std");
const interpreter = @import("interpreter.zig");
const io = @import("io.zig");

const spoon = @import("spoon");
var term: spoon.Term = undefined;
var args: [][:0]u8 = undefined;
var intp: *interpreter.Interpreter = undefined;

pub fn main() anyerror!void {
    //--- befunge initialization ----------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);
    if (args.len < 2) {
        std.debug.print("Usage: {s} <b98_file_to_run>\n", .{args[0]});
        std.os.exit(1);
    }

    var file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    const env: []const [*:0]const u8 = std.os.environ;
    intp = try interpreter.Interpreter.init(gpa.allocator(), file.reader(), null, args, env[0..]);
    defer intp.deinit();

    var ioContext = io.context(std.io.getStdIn().reader(), std.io.getStdOut().writer()); // TODO io functions for tui

    //--- Term initialization -------------------------------------------------
    try term.init(.{});
    defer term.deinit();

    try std.os.sigaction(std.os.SIG.WINCH, &std.os.Sigaction{
        .handler = .{ .handler = handleSigWinch },
        .mask = std.os.empty_sigset,
        .flags = 0,
    }, null);

    var fds: [1]std.os.pollfd = undefined;
    fds[0] = .{
        .fd = term.tty.handle,
        .events = std.os.POLL.IN,
        .revents = undefined,
    };
    try term.uncook(.{});
    defer term.cook() catch {};

    //--- Main loop -----------------------------------------------------------
    try term.fetchSize();
    try term.setWindowTitle("zigfunge98-tui", .{});
    try render();

    var buf: [16]u8 = undefined;
    var done = false;
    while (!done) {
        _ = try std.os.poll(&fds, -1);

        const read = try term.readInput(&buf);
        var it = spoon.inputParser(buf[0..read]);
        while (it.next()) |in| {
            if (in.eqlDescription("escape") or in.eqlDescription("q")) {
                done = true;
                break;
            } else if (in.eqlDescription("s")) {
                if (try intp.step(&ioContext)) |code| {
                    std.os.exit(@intCast(u8, code));
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

    const pointer = intp.getPointer().getInfo();

    try rc.moveCursorTo(0, 0);
    var filename = rc.restrictedPaddingWriter(term.width);
    try filename.writer().print("{s} | steps:{d}", .{ args[1], 0 });

    try rc.moveCursorTo(2, 0);
    try rc.setAttribute(.{ .fg = .green, .reverse = true });
    var stack = rc.restrictedPaddingWriter(16);
    try stack.writer().writeAll("---- Stack ----");

    try rc.moveCursorTo(2, 18);
    try rc.setAttribute(.{ .fg = .blue, .reverse = true });
    var fieldTitle = rc.restrictedPaddingWriter(term.width - 17);
    const size = intp.getField().getSize();
    try fieldTitle.writer().print("Funge field | top left corner:({d},{d}) size:{d}x{d}", .{ size[0], size[1], size[2], size[3] });
    try fieldTitle.pad();
    try rc.setAttribute(.{ .fg = .blue, .reverse = false });
    var y: usize = 0; // TODO negative lines
    while (y < @min(@intCast(usize, size[3]), term.height - 3)) : (y += 1) {
        var field = rc.restrictedPaddingWriter(term.width - 17);
        const line = intp.getField().getLine(y);
        const data = line.getData();
        var x: usize = 0;
        if (line.getX() >= 0) {
            try rc.moveCursorTo(y + 3, 18 + @intCast(usize, line.getX()));
        } else {
            try rc.moveCursorTo(y + 3, 18); // TODO negative columns
        }
        while (x < @min(data.items.len, term.width - 18)) : (x += 1) {
            if (x == pointer.x and y == pointer.y) {
                try rc.setAttribute(.{ .fg = .magenta, .reverse = true });
            }
            if (x == pointer.x + pointer.dx and y == pointer.y + pointer.dy) { // TODO optmize that?
                try rc.setAttribute(.{ .fg = .magenta, .reverse = false });
            }
            if (data.items[x] >= 32 and data.items[x] < 127) {
                try field.writer().print("{c}", .{@intCast(u8, data.items[x])});
            } else {
                try field.writer().writeAll("®");
            }
            if (x == pointer.x and y == pointer.y or x == pointer.x + pointer.dx and y == pointer.y + pointer.dy) {
                try rc.setAttribute(.{ .fg = .blue, .reverse = false });
            }
        }
    }
}
