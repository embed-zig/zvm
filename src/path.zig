const std = @import("std");

pub fn rootDir(allocator: std.mem.Allocator) ![]const u8 {
    if (std.process.getEnvVarOwned(allocator, "ZVM_HOME")) |value| {
        return value;
    } else |err| switch (err) {
        error.EnvironmentVariableNotFound => {},
        else => return err,
    }

    const home = std.process.getEnvVarOwned(allocator, "HOME") catch |home_err| switch (home_err) {
        error.EnvironmentVariableNotFound => try std.process.getEnvVarOwned(allocator, "USERPROFILE"),
        else => return home_err,
    };
    defer allocator.free(home);

    return std.fs.path.join(allocator, &.{ home, ".zvm" });
}

pub fn binDir(allocator: std.mem.Allocator) ![]const u8 {
    const root = try rootDir(allocator);
    defer allocator.free(root);
    return std.fs.path.join(allocator, &.{ root, "bin" });
}

pub fn versionsDir(allocator: std.mem.Allocator) ![]const u8 {
    const root = try rootDir(allocator);
    defer allocator.free(root);
    return std.fs.path.join(allocator, &.{ root, "versions" });
}

pub fn tmpDir(allocator: std.mem.Allocator) ![]const u8 {
    const root = try rootDir(allocator);
    defer allocator.free(root);
    return std.fs.path.join(allocator, &.{ root, "tmp" });
}

pub fn versionDir(allocator: std.mem.Allocator, version: []const u8) ![]const u8 {
    const versions = try versionsDir(allocator);
    defer allocator.free(versions);
    return std.fs.path.join(allocator, &.{ versions, version });
}

pub fn zigPath(allocator: std.mem.Allocator, version: []const u8) ![]const u8 {
    const dir = try versionDir(allocator, version);
    defer allocator.free(dir);
    return std.fs.path.join(allocator, &.{ dir, zigExecutableName() });
}

pub fn zigLinkPath(allocator: std.mem.Allocator) ![]const u8 {
    const bin = try binDir(allocator);
    defer allocator.free(bin);
    return std.fs.path.join(allocator, &.{ bin, zigExecutableName() });
}

pub fn currentFilePath(allocator: std.mem.Allocator) ![]const u8 {
    const root = try rootDir(allocator);
    defer allocator.free(root);
    return std.fs.path.join(allocator, &.{ root, "current" });
}

pub fn zigSymlinkTarget(allocator: std.mem.Allocator, version: []const u8) ![]const u8 {
    return std.fs.path.join(allocator, &.{ "..", "versions", version, zigExecutableName() });
}

pub fn ensureLayout(allocator: std.mem.Allocator) !void {
    const root = try rootDir(allocator);
    defer allocator.free(root);
    const bin = try binDir(allocator);
    defer allocator.free(bin);
    const versions = try versionsDir(allocator);
    defer allocator.free(versions);
    const tmp = try tmpDir(allocator);
    defer allocator.free(tmp);

    try std.fs.cwd().makePath(root);
    try std.fs.cwd().makePath(bin);
    try std.fs.cwd().makePath(versions);
    try std.fs.cwd().makePath(tmp);
}

pub fn zigExecutableName() []const u8 {
    return if (@import("builtin").os.tag == .windows) "zig.exe" else "zig";
}
