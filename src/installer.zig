const std = @import("std");
const semver = @import("semver.zig");
const zpath = @import("path.zig");
const registry = @import("registry.zig");

pub const InstalledList = struct {
    allocator: std.mem.Allocator,
    versions: []const []const u8,

    pub fn deinit(self: InstalledList) void {
        for (self.versions) |version| self.allocator.free(version);
        self.allocator.free(self.versions);
    }
};

pub fn listInstalled(allocator: std.mem.Allocator) !InstalledList {
    const versions_dir = try zpath.versionsDir(allocator);
    defer allocator.free(versions_dir);

    var versions: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (versions.items) |version| allocator.free(version);
        versions.deinit(allocator);
    }

    var dir = std.fs.openDirAbsolute(versions_dir, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return .{ .allocator = allocator, .versions = try versions.toOwnedSlice(allocator) },
        else => return err,
    };
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |item| {
        if (item.kind != .directory) continue;
        _ = semver.Version.parse(item.name) catch continue;
        try versions.append(allocator, try allocator.dupe(u8, item.name));
    }

    std.mem.sort([]const u8, versions.items, {}, semver.lessThan);
    return .{ .allocator = allocator, .versions = try versions.toOwnedSlice(allocator) };
}

pub fn resolveInstalled(allocator: std.mem.Allocator, pattern: []const u8) !?[]const u8 {
    const installed = try listInstalled(allocator);
    defer installed.deinit();

    const resolved = try semver.highestMatching(installed.versions, pattern);
    if (resolved) |version| {
        const copy = try allocator.dupe(u8, version);
        return @as(?[]const u8, copy);
    }
    return null;
}

pub fn isInstalled(allocator: std.mem.Allocator, version: []const u8) !bool {
    const zig = try zpath.zigPath(allocator, version);
    defer allocator.free(zig);

    std.fs.accessAbsolute(zig, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };
    return true;
}

pub fn installArtifact(allocator: std.mem.Allocator, version: []const u8, artifact: registry.Artifact) !void {
    try zpath.ensureLayout(allocator);

    const tmp_root = try zpath.tmpDir(allocator);
    defer allocator.free(tmp_root);
    const tmp_dir = try std.fs.path.join(allocator, &.{ tmp_root, version });
    defer allocator.free(tmp_dir);
    const archive_name = archiveFileName(artifact.url);
    const archive_path = try std.fs.path.join(allocator, &.{ tmp_dir, archive_name });
    defer allocator.free(archive_path);
    const extract_dir = try std.fs.path.join(allocator, &.{ tmp_dir, "extract" });
    defer allocator.free(extract_dir);

    std.fs.deleteTreeAbsolute(tmp_dir) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };
    defer std.fs.deleteTreeAbsolute(tmp_dir) catch {};

    try std.fs.cwd().makePath(extract_dir);
    try materializeArchive(allocator, artifact.url, archive_path);

    const actual = try sha256File(allocator, archive_path);
    defer allocator.free(actual);
    if (!std.mem.eql(u8, actual, artifact.sha256)) return error.ChecksumMismatch;

    if (@import("builtin").os.tag == .windows) {
        const tar_archive_path = try windowsTarPath(allocator, archive_path);
        defer allocator.free(tar_archive_path);
        const tar_extract_dir = try windowsTarPath(allocator, extract_dir);
        defer allocator.free(tar_extract_dir);
        try run(allocator, &.{ "tar", "--force-local", "-xf", tar_archive_path, "-C", tar_extract_dir });
    } else {
        try run(allocator, &.{ "tar", "-xf", archive_path, "-C", extract_dir });
    }

    const zig_source = try findZigExecutable(allocator, extract_dir);
    defer allocator.free(zig_source);

    const version_dir = try zpath.versionDir(allocator, version);
    defer allocator.free(version_dir);
    std.fs.deleteTreeAbsolute(version_dir) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };
    try std.fs.cwd().makePath(version_dir);

    const zig_dest = try zpath.zigPath(allocator, version);
    defer allocator.free(zig_dest);
    try std.fs.copyFileAbsolute(zig_source, zig_dest, .{});
    if (@import("builtin").os.tag != .windows) {
        try run(allocator, &.{ "chmod", "+x", zig_dest });
    }
}

pub fn useVersion(allocator: std.mem.Allocator, version: []const u8) !void {
    if (!try isInstalled(allocator, version)) return error.VersionNotInstalled;

    try zpath.ensureLayout(allocator);

    const bin_dir = try zpath.binDir(allocator);
    defer allocator.free(bin_dir);
    const link_target = try zpath.zigSymlinkTarget(allocator, version);
    defer allocator.free(link_target);

    var bin = try std.fs.openDirAbsolute(bin_dir, .{});
    defer bin.close();
    bin.deleteFile(zpath.zigExecutableName()) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };
    bin.symLink(link_target, zpath.zigExecutableName(), .{}) catch |sym_err| switch (sym_err) {
        error.AccessDenied, error.Unexpected => {
            const zig = try zpath.zigPath(allocator, version);
            defer allocator.free(zig);
            const link = try zpath.zigLinkPath(allocator);
            defer allocator.free(link);
            try std.fs.copyFileAbsolute(zig, link, .{});
        },
        else => return sym_err,
    };

    const current = try zpath.currentFilePath(allocator);
    defer allocator.free(current);
    const file = try std.fs.createFileAbsolute(current, .{ .truncate = true });
    defer file.close();
    try file.writeAll(version);
    try file.writeAll("\n");
}

pub fn currentVersion(allocator: std.mem.Allocator) !?[]const u8 {
    const current = try zpath.currentFilePath(allocator);
    defer allocator.free(current);

    const contents = std.fs.cwd().readFileAlloc(allocator, current, 1024) catch |err| switch (err) {
        error.FileNotFound => return try currentFromSymlink(allocator),
        else => return err,
    };
    defer allocator.free(contents);

    const trimmed = std.mem.trim(u8, contents, " \t\r\n");
    if (trimmed.len == 0) return try currentFromSymlink(allocator);
    const copy = try allocator.dupe(u8, trimmed);
    return @as(?[]const u8, copy);
}

pub fn uninstall(allocator: std.mem.Allocator, version: []const u8) !void {
    const dir = try zpath.versionDir(allocator, version);
    defer allocator.free(dir);
    std.fs.deleteTreeAbsolute(dir) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };

    if (try currentVersion(allocator)) |current| {
        defer allocator.free(current);
        if (std.mem.eql(u8, current, version)) {
            const link = try zpath.zigLinkPath(allocator);
            defer allocator.free(link);
            std.fs.deleteFileAbsolute(link) catch |err| switch (err) {
                error.FileNotFound => {},
                else => return err,
            };
            const current_file = try zpath.currentFilePath(allocator);
            defer allocator.free(current_file);
            std.fs.deleteFileAbsolute(current_file) catch |err| switch (err) {
                error.FileNotFound => {},
                else => return err,
            };
        }
    }
}

pub fn currentFromSymlink(allocator: std.mem.Allocator) !?[]const u8 {
    const link = try zpath.zigLinkPath(allocator);
    defer allocator.free(link);

    var buffer: [std.fs.max_path_bytes]u8 = undefined;
    const target = std.fs.readLinkAbsolute(link, &buffer) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };

    const needle = "versions/";
    const start = std.mem.indexOf(u8, target, needle) orelse return null;
    const rest = target[start + needle.len ..];
    const slash = std.mem.indexOfScalar(u8, rest, '/') orelse return null;
    const copy = try allocator.dupe(u8, rest[0..slash]);
    return @as(?[]const u8, copy);
}

fn materializeArchive(allocator: std.mem.Allocator, url: []const u8, output_path: []const u8) !void {
    if (std.mem.startsWith(u8, url, "file://")) {
        try std.fs.copyFileAbsolute(url["file://".len..], output_path, .{});
        return;
    }

    if (std.fs.path.isAbsolute(url)) {
        try std.fs.copyFileAbsolute(url, output_path, .{});
        return;
    }

    if (std.mem.startsWith(u8, url, "http://") or std.mem.startsWith(u8, url, "https://")) {
        if (run(allocator, &.{ "curl", "-fsSL", url, "-o", output_path })) |_| {
            return;
        } else |_| {
            try run(allocator, &.{ "wget", "-q", url, "-O", output_path });
            return;
        }
    }

    try std.fs.cwd().copyFile(url, std.fs.cwd(), output_path, .{});
}

fn archiveFileName(url: []const u8) []const u8 {
    const without_query = if (std.mem.indexOfScalar(u8, url, '?')) |index| url[0..index] else url;
    var start: usize = 0;
    for (without_query, 0..) |char, index| {
        if (char == '/' or char == '\\') start = index + 1;
    }
    const base = without_query[start..];
    return if (base.len == 0) "archive" else base;
}

fn windowsTarPath(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    const copy = try allocator.dupe(u8, path);
    for (copy) |*char| {
        if (char.* == '\\') char.* = '/';
    }
    return copy;
}

fn sha256File(allocator: std.mem.Allocator, file_path: []const u8) ![]const u8 {
    const contents = try std.fs.cwd().readFileAlloc(allocator, file_path, 512 * 1024 * 1024);
    defer allocator.free(contents);

    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(contents, &digest, .{});

    const hex = try allocator.alloc(u8, digest.len * 2);
    const alphabet = "0123456789abcdef";
    for (digest, 0..) |byte, index| {
        hex[index * 2] = alphabet[byte >> 4];
        hex[index * 2 + 1] = alphabet[byte & 0x0f];
    }
    return hex;
}

fn findZigExecutable(allocator: std.mem.Allocator, root: []const u8) ![]const u8 {
    var dir = try std.fs.openDirAbsolute(root, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.eql(u8, std.fs.path.basename(entry.path), zpath.zigExecutableName())) continue;
        return try std.fs.path.join(allocator, &.{ root, entry.path });
    }

    return error.ZigExecutableNotFound;
}

fn run(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
        .max_output_bytes = 256 * 1024,
    });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    switch (result.term) {
        .Exited => |code| if (code == 0) return,
        else => {},
    }

    std.debug.print("command failed:", .{});
    for (argv) |arg| std.debug.print(" {s}", .{arg});
    std.debug.print("\n", .{});
    if (result.stderr.len > 0) std.debug.print("{s}\n", .{result.stderr});
    if (result.stdout.len > 0) std.debug.print("{s}\n", .{result.stdout});
    return error.CommandFailed;
}
