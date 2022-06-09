const std = @import("std");
const field = @import("field.zig");
const pointer = @import("pointer.zig");

pub const Interpreter = struct {
    allocator: std.mem.Allocator,
    field: *field.Field,
    pointer: *pointer.Pointer,

    pub fn deinit(self: *Interpreter) void {
        self.allocator.destroy(self);
    }
    pub fn init(allocator: std.mem.Allocator, f: *field.Field, p: *pointer.Pointer) !*Interpreter {
        var i = try allocator.create(Interpreter);
        errdefer allocator.destroy(i);
        i.allocator = allocator;
        i.field = f;
        i.pointer = p;
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
