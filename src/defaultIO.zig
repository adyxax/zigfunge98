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
    // TODO
    _ = v;
    return error.NotImplemented;
}

pub fn decimalOutput(v: i64) IOErrors!void {
    // TODO
    _ = v;
    return error.NotImplemented;
}

test "all" {
    std.testing.refAllDecls(@This());
}
