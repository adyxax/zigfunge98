const std = @import("std");

pub const IOErrors = error{
    IOError,
    NotImplemented,
};

pub fn characterInput() IOErrors!i64 {
    // TODO
    return error.NotImplemented;
}

pub fn decimalInput() IOErrors!i64 {
    // TODO
    return error.NotImplemented;
}

pub fn characterOutput(v: i64) IOErrors!void {
    std.debug.print("{c}", .{@intCast(u8, v)});
    return;
}

pub fn decimalOutput(v: i64) IOErrors!void {
    std.debug.print("{d}", .{v});
    return;
}

test "all" {
    std.testing.refAllDecls(@This());
}
