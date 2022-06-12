const std = @import("std");
const field = @import("field.zig");
const pointer = @import("pointer.zig");

pub const Interpreter = struct {
    allocator: std.mem.Allocator,
    field: *field.Field,
    pointer: *pointer.Pointer,

    pub fn deinit(self: *Interpreter) void {
        self.pointer.deinit();
        self.field.deinit();
        self.allocator.destroy(self);
    }
    pub fn init(allocator: std.mem.Allocator, reader: anytype, ioFunctions: ?pointer.IOFunctions, args: []const []const u8) !*Interpreter {
        var i = try allocator.create(Interpreter);
        errdefer allocator.destroy(i);
        i.allocator = allocator;
        i.field = try field.Field.init_from_reader(allocator, reader);
        errdefer i.field.deinit();
        i.pointer = try pointer.Pointer.init(std.testing.allocator, i.field, ioFunctions, args);
        errdefer i.pointer.deinit();
        return i;
    }
    pub fn run(self: *Interpreter) !i64 {
        while (true) {
            if (try self.pointer.exec()) |ret| {
                if (ret.code) |code| {
                    return code;
                } else {
                    return 0;
                }
            }
        }
    }
};

test "all" {
    std.testing.refAllDecls(@This());
}
