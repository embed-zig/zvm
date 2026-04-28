const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zvm",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    b.step("run", "Run zvm").dependOn(&run_cmd.step);

    const semver_mod = b.createModule(.{
        .root_source_file = b.path("src/semver.zig"),
        .target = target,
        .optimize = optimize,
    });
    const registry_mod = b.createModule(.{
        .root_source_file = b.path("src/registry.zig"),
        .target = target,
        .optimize = optimize,
    });
    const path_mod = b.createModule(.{
        .root_source_file = b.path("src/path.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    inline for (.{
        "test/semver_test.zig",
        "test/registry_test.zig",
        "test/installer_test.zig",
    }) |test_path| {
        const test_mod = b.createModule(.{
            .root_source_file = b.path(test_path),
            .target = target,
            .optimize = optimize,
        });
        test_mod.addImport("semver", semver_mod);
        test_mod.addImport("registry", registry_mod);
        test_mod.addImport("zvm-path", path_mod);

        const unit_tests = b.addTest(.{ .root_module = test_mod });
        const run_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_tests.step);
    }
}
