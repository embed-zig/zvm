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
    const embedded_registry_source = generateEmbeddedRegistry(b) catch |err| {
        std.debug.panic("failed to generate embedded registry: {s}", .{@errorName(err)});
    };
    const generated = b.addWriteFiles();
    const embedded_registry_path = generated.add("embedded_registry.zig", embedded_registry_source);
    const embedded_registry_mod = b.createModule(.{
        .root_source_file = embedded_registry_path,
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("embedded_registry", embedded_registry_mod);
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
    registry_mod.addImport("embedded_registry", embedded_registry_mod);
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

fn generateEmbeddedRegistry(b: *std.Build) ![]const u8 {
    const allocator = b.allocator;

    var dir = try std.fs.cwd().openDir("registry", .{ .iterate = true });
    defer dir.close();

    var names: std.ArrayList([]const u8) = .empty;
    defer {
        for (names.items) |name| allocator.free(name);
        names.deinit(allocator);
    }

    var it = dir.iterate();
    while (try it.next()) |item| {
        if (item.kind != .file) continue;
        if (!std.mem.endsWith(u8, item.name, ".zon")) continue;
        try names.append(allocator, try allocator.dupe(u8, item.name));
    }
    std.mem.sort([]const u8, names.items, {}, stringLessThan);

    var source: std.ArrayList(u8) = .empty;
    errdefer source.deinit(allocator);
    try source.appendSlice(allocator,
        \\pub const Entry = struct {
        \\    version: []const u8,
        \\    contents: []const u8,
        \\};
        \\
        \\pub const entries = [_]Entry{
        \\
    );

    for (names.items) |name| {
        const version = name[0 .. name.len - ".zon".len];
        const path = try std.fs.path.join(allocator, &.{ "registry", name });
        defer allocator.free(path);

        const contents = try std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024);
        defer allocator.free(contents);

        try source.writer(allocator).print(
            \\    .{{
            \\        .version = "{s}",
            \\        .contents = @as([]const u8, &.{{
            \\
        , .{version});
        for (contents, 0..) |byte, index| {
            if (index % 16 == 0) try source.appendSlice(allocator, "            ");
            try source.writer(allocator).print("{d}, ", .{byte});
            if (index % 16 == 15) try source.append(allocator, '\n');
        }
        if (contents.len % 16 != 0) try source.append(allocator, '\n');
        try source.appendSlice(allocator,
            \\        }),
            \\    },
            \\
        );
    }

    try source.appendSlice(allocator, "};\n");
    return source.toOwnedSlice(allocator);
}

fn stringLessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}
