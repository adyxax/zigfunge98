const std = @import("std");
const interpreter = @import("interpreter.zig");
const io = @import("io.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    var args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);
    if (args.len < 2) {
        std.debug.print("Usage: {s} <b98_file_to_run>\n", .{args[0]});
        std.os.exit(1);
    }

    var file = try std.fs.cwd().openFile("mycology/sanity.bf", .{});
    defer file.close();

    var i = try interpreter.Interpreter.init(gpa.allocator(), file.reader(), args);
    defer i.deinit();

    var ioContext = io.context(std.io.getStdIn().reader(), std.io.getStdOut().writer());
    std.os.exit(@intCast(u8, try i.run(&ioContext)));
}

test "all" {
    std.testing.refAllDecls(@This());
}
test "sanity" {
    var file = try std.fs.cwd().openFile("mycology/sanity.bf", .{});
    defer file.close();
    var stdin = std.io.fixedBufferStream("");
    var stdout = std.ArrayList(u8).init(std.testing.allocator);
    defer stdout.deinit();
    const expected = "0123456789";
    const args = [_][]const u8{"sanity"};
    var i = try interpreter.Interpreter.init(std.testing.allocator, file.reader(), args[0..]);
    defer i.deinit();
    var ioContext = io.context(stdin.reader(), stdout.writer());
    try std.testing.expectEqual(try i.run(&ioContext), 0);
    try std.testing.expectEqual(std.mem.eql(u8, stdout.items, expected), true);
}
