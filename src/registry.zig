const std = @import("std");
const semver = @import("semver.zig");
const embedded_registry = @import("embedded_registry").entries;

pub const Entry = struct {
    version: []const u8,
    file_path: []const u8,
    embedded_contents: ?[]const u8 = null,
};

pub const Artifact = struct {
    allocator: std.mem.Allocator,
    url: []const u8,
    sha256: []const u8,

    pub fn deinit(self: Artifact) void {
        self.allocator.free(self.url);
        self.allocator.free(self.sha256);
    }
};

pub const Registry = struct {
    allocator: std.mem.Allocator,
    entries: []Entry,

    pub fn deinit(self: Registry) void {
        for (self.entries) |entry| {
            self.allocator.free(entry.version);
            self.allocator.free(entry.file_path);
        }
        self.allocator.free(self.entries);
    }

    pub fn resolve(self: Registry, pattern: []const u8) !?Entry {
        var best: ?Entry = null;
        var best_version: ?semver.Version = null;

        for (self.entries) |entry| {
            if (!semver.matchesPattern(entry.version, pattern)) continue;
            const parsed = try semver.Version.parse(entry.version);
            if (best_version == null or parsed.compare(best_version.?) == .gt) {
                best = entry;
                best_version = parsed;
            }
        }

        return best;
    }
};

pub fn load(allocator: std.mem.Allocator, registry_dir: []const u8) !Registry {
    var dir = try std.fs.cwd().openDir(registry_dir, .{ .iterate = true });
    defer dir.close();

    var entries: std.ArrayList(Entry) = .empty;
    errdefer {
        for (entries.items) |entry| {
            allocator.free(entry.version);
            allocator.free(entry.file_path);
        }
        entries.deinit(allocator);
    }

    var it = dir.iterate();
    while (try it.next()) |item| {
        if (item.kind != .file) continue;
        if (!std.mem.endsWith(u8, item.name, ".zon")) continue;

        const version = item.name[0 .. item.name.len - ".zon".len];
        _ = semver.Version.parse(version) catch continue;

        try entries.append(allocator, .{
            .version = try allocator.dupe(u8, version),
            .file_path = try std.fs.path.join(allocator, &.{ registry_dir, item.name }),
        });
    }

    std.mem.sort(Entry, entries.items, {}, entryLessThan);
    return .{
        .allocator = allocator,
        .entries = try entries.toOwnedSlice(allocator),
    };
}

pub fn loadEmbedded(allocator: std.mem.Allocator) !Registry {
    var entries: std.ArrayList(Entry) = .empty;
    errdefer {
        for (entries.items) |entry| {
            allocator.free(entry.version);
            allocator.free(entry.file_path);
        }
        entries.deinit(allocator);
    }

    for (embedded_registry) |embedded| {
        _ = try semver.Version.parse(embedded.version);
        try entries.append(allocator, .{
            .version = try allocator.dupe(u8, embedded.version),
            .file_path = try std.fmt.allocPrint(allocator, "embedded://registry/{s}.zon", .{embedded.version}),
            .embedded_contents = embedded.contents,
        });
    }

    std.mem.sort(Entry, entries.items, {}, entryLessThan);
    return .{
        .allocator = allocator,
        .entries = try entries.toOwnedSlice(allocator),
    };
}

pub fn loadDefault(allocator: std.mem.Allocator) !Registry {
    if (std.process.getEnvVarOwned(allocator, "ZVM_REGISTRY_DIR")) |value| {
        defer allocator.free(value);
        return load(allocator, value);
    } else |err| switch (err) {
        error.EnvironmentVariableNotFound => return loadEmbedded(allocator),
        else => return err,
    }
}

pub fn readArtifactUrl(allocator: std.mem.Allocator, entry: Entry, target: []const u8) !?[]const u8 {
    const artifact = try readArtifact(allocator, entry, target);
    if (artifact) |value| {
        defer value.deinit();
        return try allocator.dupe(u8, value.url);
    }
    return null;
}

pub fn readArtifact(allocator: std.mem.Allocator, entry: Entry, target: []const u8) !?Artifact {
    var allocated_contents: ?[]u8 = null;
    const contents = if (entry.embedded_contents) |embedded_contents|
        embedded_contents
    else blk: {
        const loaded = try std.fs.cwd().readFileAlloc(allocator, entry.file_path, 1024 * 1024);
        allocated_contents = loaded;
        break :blk loaded;
    };
    defer if (allocated_contents) |loaded| allocator.free(loaded);

    var index: usize = 0;
    while (std.mem.indexOfPos(u8, contents, index, ".target")) |target_key| {
        const target_value = extractQuotedValue(contents[target_key..]) orelse break;
        const block_end = std.mem.indexOfPos(u8, contents, target_key, "},") orelse contents.len;
        if (std.mem.eql(u8, target_value, target)) {
            const url_key = std.mem.indexOfPos(u8, contents, target_key, ".url") orelse return null;
            const sha_key = std.mem.indexOfPos(u8, contents, target_key, ".sha256") orelse return null;
            if (url_key >= block_end or sha_key >= block_end) return null;
            const url = extractQuotedValue(contents[url_key..]) orelse return null;
            const sha256 = extractQuotedValue(contents[sha_key..]) orelse return null;
            return .{
                .allocator = allocator,
                .url = try allocator.dupe(u8, url),
                .sha256 = try allocator.dupe(u8, sha256),
            };
        }
        index = target_key + ".target".len;
    }

    return null;
}

fn entryLessThan(_: void, a: Entry, b: Entry) bool {
    return semver.lessThan({}, a.version, b.version);
}

fn extractQuotedValue(text: []const u8) ?[]const u8 {
    const equals = std.mem.indexOfScalar(u8, text, '=') orelse return null;
    const first_quote_rel = std.mem.indexOfScalar(u8, text[equals + 1 ..], '"') orelse return null;
    const first_quote = equals + 1 + first_quote_rel;
    const second_quote_rel = std.mem.indexOfScalar(u8, text[first_quote + 1 ..], '"') orelse return null;
    return text[first_quote + 1 .. first_quote + 1 + second_quote_rel];
}

