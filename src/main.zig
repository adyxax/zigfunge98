const std = @import("std");
const interpreter = @import("interpreter.zig");
const io = @import("io.zig");

pub fn main() anyerror!void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    var args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    if (args.len < 2) {
        std.debug.print("Usage: {s} <b98_file_to_run>\n", .{args[0]});
        std.os.exit(1);
    }

    var file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();

    const env: []const [*:0]const u8 = std.os.environ;
    var i = try interpreter.Interpreter.init(gpa, file.reader(), null, args, env[0..]);
    defer i.deinit();

    var ioContext = io.context(std.io.getStdIn().reader(), std.io.getStdOut().writer());
    std.os.exit(@intCast(try i.run(&ioContext)));
}

const testTimestamp: i64 = 1660681247;

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
    const args = [_][]const u8{ "test", "sanity" };
    const env = [_][*:0]const u8{ "ENV=TEST", "FOO=BAR" };
    var i = try interpreter.Interpreter.init(std.testing.allocator, file.reader(), testTimestamp, args[0..], env[0..]);
    defer i.deinit();
    var ioContext = io.context(stdin.reader(), stdout.writer());
    try std.testing.expectEqual(try i.run(&ioContext), 0);
    try std.testing.expectEqual(std.mem.eql(u8, stdout.items, expected), true);
}
test "mycology" {
    var file = try std.fs.cwd().openFile("mycology/mycology.b98", .{});
    defer file.close();
    var stdin = std.io.fixedBufferStream("");
    var stdout = std.ArrayList(u8).init(std.testing.allocator);
    defer stdout.deinit();
    var expected = try std.fs.cwd().openFile("tests/mycology.stdout", .{});
    defer expected.close();
    const expectedOutput = try expected.reader().readAllAlloc(std.testing.allocator, 8192);
    defer std.testing.allocator.free(expectedOutput);
    const args = [_][]const u8{ "test", "sanity" };
    const env = [_][*:0]const u8{ "ENV=TEST", "FOO=BAR" };
    var i = try interpreter.Interpreter.init(std.testing.allocator, file.reader(), testTimestamp, args[0..], env[0..]);
    defer i.deinit();
    var ioContext = io.context(stdin.reader(), stdout.writer());
    try std.testing.expectEqual(try i.run(&ioContext), 15);
    try std.testing.expectEqual(std.mem.eql(u8, stdout.items, expectedOutput), true);
}
