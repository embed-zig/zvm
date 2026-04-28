const std = @import("std");
const registry = @import("registry");

test "registry loads flat version files and resolves patterns" {
    const allocator = std.testing.allocator;
    const reg = try registry.load(allocator, "test/fixtures/registry");
    defer reg.deinit();

    try std.testing.expectEqual(@as(usize, 4), reg.entries.len);
    try std.testing.expectEqualStrings("0.15.2-esp.r4", reg.entries[0].version);
    try std.testing.expectEqualStrings("0.15.2", reg.entries[1].version);
    try std.testing.expectEqualStrings("0.16.0", reg.entries[2].version);
    try std.testing.expectEqualStrings("0.17.0-dev.135+9df02121d", reg.entries[3].version);

    const esp = (try reg.resolve("0.15.2-esp.*")).?;
    try std.testing.expectEqualStrings("0.15.2-esp.r4", esp.version);

    const official = (try reg.resolve("0.16.*")).?;
    try std.testing.expectEqualStrings("0.16.0", official.version);

    const dev = (try reg.resolve("0.17.*")).?;
    try std.testing.expectEqualStrings("0.17.0-dev.135+9df02121d", dev.version);
}

test "release registry entries include supported host targets" {
    const allocator = std.testing.allocator;
    const reg = try registry.load(allocator, "registry");
    defer reg.deinit();

    const targets = [_][]const u8{
        "macos-x86_64",
        "macos-aarch64",
        "linux-x86_64",
        "linux-aarch64",
        "windows-x86_64",
        "windows-aarch64",
    };

    for (reg.entries) |entry| {
        for (targets) |target| {
            const url = try registry.readArtifactUrl(allocator, entry, target);
            try std.testing.expect(url != null);
            allocator.free(url.?);
        }
    }
}
