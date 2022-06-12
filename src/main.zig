const std = @import("std");
const field = @import("field.zig");
const interpreter = @import("interpreter.zig");
const pointer = @import("pointer.zig");
const stackStack = @import("stackStack.zig");

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

    var i = try interpreter.Interpreter.init(gpa.allocator(), file.reader(), null, args);
    defer i.deinit();

    std.os.exit(@intCast(u8, try i.run()));
}

test "all" {
    std.testing.refAllDecls(@This());
}
test "sanity" {
    var file = try std.fs.cwd().openFile("mycology/sanity.bf", .{});
    defer file.close();
    const args = [_][]const u8{"sanity"};
    var i = try interpreter.Interpreter.init(std.testing.allocator, file.reader(), null, args[0..]);
    defer i.deinit();
    try std.testing.expectEqual(try i.run(), 0);
}
