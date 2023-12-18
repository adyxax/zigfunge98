const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zigfunge98",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const coverage = b.option(bool, "test-coverage", "Generate test coverage") orelse false;
    // Code coverage with kcov, we need an allocator for the setup
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    // We want to exclude the $HOME/.zig path
    const home = std.process.getEnvVarOwned(gpa, "HOME") catch "";
    defer gpa.free(home);
    const exclude = std.fmt.allocPrint(gpa, "--exclude-path={s}/.zig/", .{home}) catch "";
    defer gpa.free(exclude);
    if (coverage) {
        unit_tests.test_runner = "/usr/bin/kcov";
        unit_tests.setExecCmd(&[_]?[]const u8{
            "kcov",
            exclude,
            //"--path-strip-level=3", // any kcov flags can be specified here
            "kcov-output", // output dir for kcov
            null, // to get zig to use the --test-cmd-bin flag
        });
    }

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // ----- TUI --------------------------------------------------------------
    const tui = b.addExecutable(.{
        .name = "zigfunge98-tui",
        .root_source_file = .{ .path = "src/tui.zig" },
        .target = target,
        .optimize = optimize,
    });
    const spoon = b.createModule(.{
        .source_file = .{ .path = "lib/spoon/import.zig" },
    });
    tui.addModule("spoon", spoon);
    b.installArtifact(tui);
    const tui_cmd = b.addRunArtifact(tui);
    tui_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        tui_cmd.addArgs(args);
    }
    const tui_step = b.step("run-tui", "Run the app");
    tui_step.dependOn(&tui_cmd.step);
    const tui_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tui.zig" },
        .target = target,
        .optimize = optimize,
    });
    const tui_run_unit_tests = b.addRunArtifact(tui_unit_tests);
    const tui_test_step = b.step("test-tui", "Run tui unit tests");
    tui_test_step.dependOn(&tui_run_unit_tests.step);
}
