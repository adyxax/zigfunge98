const std = @import("std");

pub fn Context(readerType: anytype, writerType: anytype) type {
    return struct {
        reader: readerType,
        writer: writerType,
        lastChar: ?i64 = null,
        allocator: std.mem.Allocator,
        const Self = @This();
        pub fn deinit(self: *Self) void {
            self.allocator.destroy(self);
        }
        pub fn init(allocator: std.mem.Allocator, reader: readerType, writer: writerType) !*Self {
            var c = try allocator.create(Self);
            c.allocator = allocator;
            c.reader = reader;
            c.writer = writer;
            return c;
        }
        pub fn characterInput(self: *Self) !i64 {
            if (self.lastChar) |c| {
                self.lastChar = null;
                return c;
            }
            var buffer = [_]u8{0};
            var n = try self.reader.read(buffer[0..]);
            if (n == 1) {
                return buffer[0];
            }
            return error.IOError;
        }
        test "characterInput" {
            var stdin = std.io.fixedBufferStream("ab0");
            var stdout = std.ArrayList(u8).init(std.testing.allocator);
            defer stdout.deinit();
            var ioContext = try context(std.testing.allocator, stdin, stdout);
            defer ioContext.deinit();
            try std.testing.expectEqual(try ioContext.characterInput(), 'a');
            try std.testing.expectEqual(try ioContext.characterInput(), 'b');
            try std.testing.expectEqual(try ioContext.characterInput(), '0');
            try std.testing.expectEqual(ioContext.characterInput(), error.IOError);
        }
        pub fn decimalInput(self: *Self) !i64 {
            var result: i64 = undefined;
            while (true) { // Fist we need to find the next numeric char
                const c = self.characterInput() catch return error.IOError;
                if (c >= '0' and c <= '9') {
                    result = c - '0';
                    break;
                }
            }
            while (true) { // then we read until we encounter a non numeric char
                const c = self.characterInput() catch break;
                if (c >= '0' and c <= '9') {
                    result = result * 10 + c - '0';
                } else {
                    self.lastChar = c;
                    break;
                }
            }
            return result;
        }
        test "decimalInput" {
            var stdin = std.io.fixedBufferStream("1 234abc5d6ef");
            var stdout = std.ArrayList(u8).init(std.testing.allocator);
            defer stdout.deinit();
            var ioContext = try context(std.testing.allocator, stdin, stdout);
            defer ioContext.deinit();
            try std.testing.expectEqual(try ioContext.decimalInput(), 1);
            try std.testing.expectEqual(try ioContext.decimalInput(), 234);
            try std.testing.expectEqual(try ioContext.decimalInput(), 5);
            try std.testing.expectEqual(try ioContext.decimalInput(), 6);
            try std.testing.expectEqual(ioContext.decimalInput(), error.IOError);
        }
        pub fn characterOutput(self: Self, v: i64) !void {
            try self.writer.print("{c}", .{@intCast(u8, v)});
            return;
        }
        pub fn decimalOutput(self: Self, v: i64) !void {
            try self.writer.print("{d}", .{v});
            return;
        }
    };
}

pub fn context(allocator: std.mem.Allocator, reader: anytype, writer: anytype) !*Context(@TypeOf(reader), @TypeOf(writer)) {
    return Context(@TypeOf(reader), @TypeOf(writer)).init(allocator, reader, writer);
}

test "all" {
    std.testing.refAllDecls(@This());
}
