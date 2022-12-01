const std = @import("std");
const field = @import("field.zig");
const io = @import("io.zig");
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
    pub fn init(allocator: std.mem.Allocator, fileReader: anytype, timestamp: ?i64, args: []const []const u8, env: []const [*:0]const u8) !*Interpreter {
        var i = try allocator.create(Interpreter);
        errdefer allocator.destroy(i);
        i.allocator = allocator;
        i.field = try field.Field.init_from_reader(allocator, fileReader);
        errdefer i.field.deinit();
        i.pointer = try pointer.Pointer.init(allocator, i.field, timestamp, args, env);
        errdefer i.pointer.deinit();
        return i;
    }
    pub fn run(self: *Interpreter, ioContext: anytype) !i64 {
        while (true) {
            if (try self.pointer.exec(ioContext)) |ret| {
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
