const std = @import("std");
const field = @import("field.zig");
const interpreter = @import("interpreter.zig");
const pointer = @import("pointer.zig");
const stackStack = @import("stackStack.zig");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "all" {
    std.testing.refAllDecls(@This());
}
test "minimal" {
    const minimal = std.io.fixedBufferStream("@").reader();
    var f = try field.Field.init(std.testing.allocator);
    defer f.deinit();
    try f.load(minimal);
    const argv = [_][]const u8{"minimal"};
    var p = try pointer.Pointer.init(std.testing.allocator, f, null, argv[0..]);
    defer p.deinit();

    var i = try interpreter.Interpreter.init(std.testing.allocator, f, p);
    defer i.deinit();

    var code = try i.run();
    try std.testing.expectEqual(code, 0);
}
test "almost minimal" {
    const minimal = std.io.fixedBufferStream(" @").reader();
    var f = try field.Field.init(std.testing.allocator);
    defer f.deinit();
    try f.load(minimal);
    const argv = [_][]const u8{"minimal"};
    var p = try pointer.Pointer.init(std.testing.allocator, f, null, argv[0..]);
    defer p.deinit();

    var i = try interpreter.Interpreter.init(std.testing.allocator, f, p);
    defer i.deinit();

    var code = try i.run();
    try std.testing.expectEqual(code, 0);
}
test "sanity" {
    var file = try std.fs.cwd().openFile("mycology/sanity.bf", .{});
    defer file.close();

    var f = try field.Field.init(std.testing.allocator);
    defer f.deinit();
    try f.load(file.reader());

    const argv = [_][]const u8{"sanity"};
    var p = try pointer.Pointer.init(std.testing.allocator, f, null, argv[0..]);
    defer p.deinit();

    var i = try interpreter.Interpreter.init(std.testing.allocator, f, p);
    defer i.deinit();

    var code = try i.run();
    try std.testing.expectEqual(code, 0);
}
