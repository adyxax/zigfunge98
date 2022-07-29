const std = @import("std");

pub fn Context(readerType: anytype, writerType: anytype) type {
    return struct {
        reader: readerType,
        writer: writerType,
        pub fn characterInput(self: @This()) !i64 {
            var buffer = [_]u8{0};
            var n = try self.reader.read(buffer[0..]);
            if (n == 1) {
                return buffer[0];
            }
            return error.IOError;
        }
        pub fn decimalInput(self: @This()) !i64 {
            _ = self;
            return error.NotImplemented;
        }
        pub fn characterOutput(self: @This(), v: i64) !void {
            try self.writer.print("{c}", .{@intCast(u8, v)});
            return;
        }
        pub fn decimalOutput(self: @This(), v: i64) !void {
            try self.writer.print("{d}", .{v});
            return;
        }
    };
}

pub fn context(reader: anytype, writer: anytype) Context(@TypeOf(reader), @TypeOf(writer)) {
    return .{
        .reader = reader,
        .writer = writer,
    };
}

test "all" {
    std.testing.refAllDecls(@This());
}
