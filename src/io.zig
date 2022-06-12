const std = @import("std");

pub const IOErrors = error{
    IOError,
    NotImplemented,
};

pub const Functions = struct {
    characterInput: fn () IOErrors!i64,
    decimalInput: fn () IOErrors!i64,
    characterOutput: fn (i64) IOErrors!void,
    decimalOutput: fn (i64) IOErrors!void,
};

pub const defaultFunctions = Functions{
    .characterInput = characterInput,
    .decimalInput = decimalInput,
    .characterOutput = characterOutput,
    .decimalOutput = decimalOutput,
};

fn characterInput() IOErrors!i64 {
    // TODO
    return error.NotImplemented;
}

fn decimalInput() IOErrors!i64 {
    // TODO
    return error.NotImplemented;
}

fn characterOutput(v: i64) IOErrors!void {
    std.debug.print("{c}", .{@intCast(u8, v)});
    return;
}

fn decimalOutput(v: i64) IOErrors!void {
    std.debug.print("{d}", .{v});
    return;
}

test "all" {
    std.testing.refAllDecls(@This());
}
