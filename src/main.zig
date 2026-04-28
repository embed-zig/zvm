const std = @import("std");
const installer = @import("installer.zig");
const platform = @import("platform.zig");
const registry = @import("registry.zig");
const self_update = @import("self_update.zig");
const zpath = @import("path.zig");

const version = "0.1.0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 1) {
        try help();
        return;
    }

    const command = args[1];
    if (std.mem.eql(u8, command, "--version") or std.mem.eql(u8, command, "version")) {
        try out("zvm {s}\n", .{version});
    } else if (std.mem.eql(u8, command, "help") or std.mem.eql(u8, command, "--help") or std.mem.eql(u8, command, "-h")) {
        try help();
    } else if (std.mem.eql(u8, command, "list-remote")) {
        try cmdListRemote(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "install")) {
        try cmdInstall(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "uninstall")) {
        try cmdUninstall(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "use")) {
        try cmdUse(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "current")) {
        try cmdCurrent(allocator);
    } else if (std.mem.eql(u8, command, "env")) {
        try cmdEnv(allocator);
    } else if (std.mem.eql(u8, command, "doctor")) {
        try cmdDoctor(allocator);
    } else if (std.mem.eql(u8, command, "self-update")) {
        try cmdSelfUpdate(allocator);
    } else {
        try err("unknown command: {s}\n\n", .{command});
        try help();
        std.process.exit(64);
    }
}

fn cmdListRemote(allocator: std.mem.Allocator, args: []const []const u8) !void {
    const pattern = if (args.len > 0) args[0] else "*";
    const registry_dir = try registry.defaultDir(allocator);
    defer allocator.free(registry_dir);
    const reg = try registry.load(allocator, registry_dir);
    defer reg.deinit();

    for (reg.entries) |entry| {
        if (std.mem.eql(u8, pattern, "*") or @import("semver.zig").matchesPattern(entry.version, pattern)) {
            try out("{s}\n", .{entry.version});
        }
    }
}

fn cmdInstall(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len != 1) return usage("install <version-or-pattern>");

    const registry_dir = try registry.defaultDir(allocator);
    defer allocator.free(registry_dir);
    const reg = try registry.load(allocator, registry_dir);
    defer reg.deinit();

    const entry = try reg.resolve(args[0]) orelse {
        try err("no registry entry matches '{s}'\n", .{args[0]});
        std.process.exit(1);
    };

    const target = try platform.currentTargetTag(allocator);
    defer allocator.free(target);
    const artifact = try registry.readArtifact(allocator, entry, target);
    defer if (artifact) |value| value.deinit();

    try out("resolved {s} -> {s}\n", .{ args[0], entry.version });
    if (artifact) |value| {
        try out("artifact for {s}: {s}\n", .{ target, value.url });
        try installer.installArtifact(allocator, entry.version, value);
        try out("installed {s}\n", .{entry.version});
    } else {
        try out("no artifact listed for {s}; registry file: {s}\n", .{ target, entry.file_path });
        std.process.exit(1);
    }
}

fn cmdUninstall(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len != 1) return usage("uninstall <version>");
    try installer.uninstall(allocator, args[0]);
    try out("uninstalled {s}\n", .{args[0]});
}

fn cmdUse(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len != 1) return usage("use <installed-version-or-pattern>");

    const resolved = try installer.resolveInstalled(allocator, args[0]) orelse {
        try err("no installed version matches '{s}'\n", .{args[0]});
        std.process.exit(1);
    };
    defer allocator.free(resolved);

    installer.useVersion(allocator, resolved) catch |use_err| switch (use_err) {
        error.VersionNotInstalled => {
            try err("{s} is not installed under ~/.zvm/versions\n", .{resolved});
            std.process.exit(1);
        },
        else => return use_err,
    };
    try out("now using Zig {s}\n", .{resolved});
}

fn cmdCurrent(allocator: std.mem.Allocator) !void {
    const current = try installer.currentVersion(allocator) orelse {
        try out("none\n", .{});
        return;
    };
    defer allocator.free(current);
    try out("{s}\n", .{current});
}

fn cmdEnv(allocator: std.mem.Allocator) !void {
    const bin = try zpath.binDir(allocator);
    defer allocator.free(bin);
    try out("export PATH=\"{s}:$PATH\"\n", .{bin});
}

fn cmdDoctor(allocator: std.mem.Allocator) !void {
    try zpath.ensureLayout(allocator);

    const root = try zpath.rootDir(allocator);
    defer allocator.free(root);
    const bin = try zpath.binDir(allocator);
    defer allocator.free(bin);
    const versions = try zpath.versionsDir(allocator);
    defer allocator.free(versions);

    try out("zvm home: {s}\n", .{root});
    try out("bin dir: {s}\n", .{bin});
    try out("versions dir: {s}\n", .{versions});

    const current = try installer.currentVersion(allocator);
    defer if (current) |value| allocator.free(value);
    try out("current: {s}\n", .{current orelse "none"});
}

fn cmdSelfUpdate(allocator: std.mem.Allocator) !void {
    const message = try self_update.updateMessage(allocator, version);
    defer allocator.free(message);
    try out("{s}", .{message});
}

fn usage(text: []const u8) !void {
    try err("usage: zvm {s}\n", .{text});
    std.process.exit(64);
}

fn help() !void {
    try out(
        \\zvm {s} - Zig Version Manager
        \\
        \\Usage:
        \\  zvm list-remote [pattern]
        \\  zvm install <version-or-pattern>
        \\  zvm uninstall <version>
        \\  zvm use <installed-version-or-pattern>
        \\  zvm current
        \\  zvm env
        \\  zvm doctor
        \\  zvm self-update
        \\  zvm --version
        \\
        \\Patterns are zvm-specific matchers such as 0.15.2-esp.* and choose the
        \\highest SemVer precedence match.
        \\
    , .{version});
}

fn out(comptime fmt: []const u8, args: anytype) !void {
    var buffer: [4096]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);
    try writer.interface.print(fmt, args);
    try writer.interface.flush();
}

fn err(comptime fmt: []const u8, args: anytype) !void {
    var buffer: [4096]u8 = undefined;
    var writer = std.fs.File.stderr().writer(&buffer);
    try writer.interface.print(fmt, args);
    try writer.interface.flush();
}
