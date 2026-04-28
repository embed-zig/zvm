const std = @import("std");

pub const SemverError = error{InvalidVersion};

pub const Version = struct {
    major: u64,
    minor: u64,
    patch: u64,
    prerelease: ?[]const u8,
    build: ?[]const u8,
    text: []const u8,

    pub fn parse(input: []const u8) SemverError!Version {
        if (input.len == 0) return error.InvalidVersion;

        var version_text = input;
        var prerelease: ?[]const u8 = null;
        var build: ?[]const u8 = null;

        if (std.mem.indexOfScalar(u8, input, '+')) |plus| {
            version_text = input[0..plus];
            const metadata = input[plus + 1 ..];
            if (metadata.len == 0 or !validIdentifierParts(metadata)) return error.InvalidVersion;
            build = metadata;
        }

        var main = version_text;
        if (std.mem.indexOfScalar(u8, version_text, '-')) |dash| {
            main = version_text[0..dash];
            const pre = version_text[dash + 1 ..];
            if (pre.len == 0 or !validPrerelease(pre)) return error.InvalidVersion;
            prerelease = pre;
        }

        var parts = std.mem.splitScalar(u8, main, '.');
        const major_text = parts.next() orelse return error.InvalidVersion;
        const minor_text = parts.next() orelse return error.InvalidVersion;
        const patch_text = parts.next() orelse return error.InvalidVersion;
        if (parts.next() != null) return error.InvalidVersion;

        return .{
            .major = parseNumber(major_text) catch return error.InvalidVersion,
            .minor = parseNumber(minor_text) catch return error.InvalidVersion,
            .patch = parseNumber(patch_text) catch return error.InvalidVersion,
            .prerelease = prerelease,
            .build = build,
            .text = input,
        };
    }

    pub fn compare(a: Version, b: Version) std.math.Order {
        if (std.math.order(a.major, b.major) != .eq) return std.math.order(a.major, b.major);
        if (std.math.order(a.minor, b.minor) != .eq) return std.math.order(a.minor, b.minor);
        if (std.math.order(a.patch, b.patch) != .eq) return std.math.order(a.patch, b.patch);

        if (a.prerelease == null and b.prerelease == null) return .eq;
        if (a.prerelease == null) return .gt;
        if (b.prerelease == null) return .lt;
        return comparePrerelease(a.prerelease.?, b.prerelease.?);
    }
};

pub fn matchesPattern(version_text: []const u8, pattern: []const u8) bool {
    _ = Version.parse(version_text) catch return false;
    if (std.mem.eql(u8, pattern, "*")) return true;

    if (std.mem.endsWith(u8, pattern, ".*")) {
        const prefix = pattern[0 .. pattern.len - 2];
        return std.mem.startsWith(u8, version_text, prefix);
    }

    _ = Version.parse(pattern) catch return false;
    return std.mem.eql(u8, version_text, pattern);
}

pub fn highestMatching(versions: []const []const u8, pattern: []const u8) SemverError!?[]const u8 {
    var best_text: ?[]const u8 = null;
    var best_version: ?Version = null;

    for (versions) |version_text| {
        if (!matchesPattern(version_text, pattern)) continue;
        const parsed = try Version.parse(version_text);
        if (best_version == null or parsed.compare(best_version.?) == .gt) {
            best_version = parsed;
            best_text = version_text;
        }
    }

    return best_text;
}

pub fn lessThan(_: void, a: []const u8, b: []const u8) bool {
    const av = Version.parse(a) catch return false;
    const bv = Version.parse(b) catch return true;
    return av.compare(bv) == .lt;
}

fn parseNumber(text: []const u8) !u64 {
    if (text.len == 0) return error.InvalidVersion;
    if (text.len > 1 and text[0] == '0') return error.InvalidVersion;
    return std.fmt.parseUnsigned(u64, text, 10);
}

fn validPrerelease(text: []const u8) bool {
    return validIdentifierParts(text);
}

fn validIdentifierParts(text: []const u8) bool {
    var parts = std.mem.splitScalar(u8, text, '.');
    while (parts.next()) |part| {
        if (part.len == 0) return false;
        for (part) |c| {
            if (!std.ascii.isAlphanumeric(c) and c != '-') return false;
        }
    }
    return true;
}

fn comparePrerelease(a: []const u8, b: []const u8) std.math.Order {
    var a_parts = std.mem.splitScalar(u8, a, '.');
    var b_parts = std.mem.splitScalar(u8, b, '.');

    while (true) {
        const ai = a_parts.next();
        const bi = b_parts.next();
        if (ai == null and bi == null) return .eq;
        if (ai == null) return .lt;
        if (bi == null) return .gt;

        const item_order = compareIdentifier(ai.?, bi.?);
        if (item_order != .eq) return item_order;
    }
}

fn compareIdentifier(a: []const u8, b: []const u8) std.math.Order {
    const a_numeric = isNumericIdentifier(a);
    const b_numeric = isNumericIdentifier(b);

    if (a_numeric and b_numeric) {
        const av = std.fmt.parseUnsigned(u64, a, 10) catch return .lt;
        const bv = std.fmt.parseUnsigned(u64, b, 10) catch return .gt;
        return std.math.order(av, bv);
    }

    if (a_numeric and !b_numeric) return .lt;
    if (!a_numeric and b_numeric) return .gt;
    return std.mem.order(u8, a, b);
}

fn isNumericIdentifier(text: []const u8) bool {
    if (text.len == 0) return false;
    for (text) |c| {
        if (!std.ascii.isDigit(c)) return false;
    }
    return true;
}
