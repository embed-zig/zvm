const std = @import("std");
const semver = @import("semver");

test "SemVer precedence handles stable and prerelease versions" {
    const stable = try semver.Version.parse("0.15.2");
    const esp3 = try semver.Version.parse("0.15.2-esp.r3");
    const esp4 = try semver.Version.parse("0.15.2-esp.r4");
    const esp5 = try semver.Version.parse("0.15.2-esp.r5");
    const esp6 = try semver.Version.parse("0.15.2-esp.r6");
    const esp7 = try semver.Version.parse("0.15.2-esp.r7");
    const esp016_3 = try semver.Version.parse("0.16.0-esp.r3");
    const esp016_4 = try semver.Version.parse("0.16.0-esp.r4");
    const stable016 = try semver.Version.parse("0.16.0");
    const dev = try semver.Version.parse("0.17.0-dev.135+9df02121d");

    try std.testing.expect(stable.compare(esp4) == .gt);
    try std.testing.expect(esp4.compare(esp3) == .gt);
    try std.testing.expect(esp5.compare(esp4) == .gt);
    try std.testing.expect(esp6.compare(esp5) == .gt);
    try std.testing.expect(esp7.compare(esp6) == .gt);
    try std.testing.expect(esp016_4.compare(esp016_3) == .gt);
    try std.testing.expect(stable016.compare(esp016_4) == .gt);
    try std.testing.expect(dev.compare(stable) == .gt);
}

test "zvm wildcard patterns choose the highest matching version" {
    const versions = [_][]const u8{
        "0.15.2",
        "0.15.2-esp.r3",
        "0.15.2-esp.r4",
        "0.15.2-esp.r5",
        "0.15.2-esp.r6",
        "0.15.2-esp.r7",
        "0.16.0-esp.r1",
        "0.16.0-esp.r2",
        "0.16.0-esp.r3",
        "0.16.0-esp.r4",
        "0.16.0",
        "0.17.0-dev.135+9df02121d",
    };

    try std.testing.expectEqualStrings("0.15.2-esp.r7", (try semver.highestMatching(&versions, "0.15.2-esp.*")).?);
    try std.testing.expectEqualStrings("0.15.2-esp.r7", (try semver.highestMatching(&versions, "0.15.2-esp")).?);
    try std.testing.expectEqualStrings("0.15.2", (try semver.highestMatching(&versions, "0.15.2")).?);
    try std.testing.expectEqualStrings("0.16.0-esp.r4", (try semver.highestMatching(&versions, "0.16.0-esp.*")).?);
    try std.testing.expectEqualStrings("0.16.0-esp.r4", (try semver.highestMatching(&versions, "0.16.0-esp")).?);
    try std.testing.expectEqualStrings("0.16.0", (try semver.highestMatching(&versions, "0.16")).?);
    try std.testing.expectEqualStrings("0.16.0", (try semver.highestMatching(&versions, "0.16.*")).?);
    try std.testing.expectEqualStrings("0.17.0-dev.135+9df02121d", (try semver.highestMatching(&versions, "0")).?);
    try std.testing.expectEqualStrings("0.17.0-dev.135+9df02121d", (try semver.highestMatching(&versions, "0.17.*")).?);
    try std.testing.expectEqualStrings("0.17.0-dev.135+9df02121d", (try semver.highestMatching(&versions, "0.17.0-dev")).?);
}

test "build metadata is legal and ignored for precedence" {
    const a = try semver.Version.parse("0.17.0-dev.135+9df02121d");
    const b = try semver.Version.parse("0.17.0-dev.135+otherbuild");

    try std.testing.expect(a.compare(b) == .eq);
}

test "invalid versions are rejected" {
    try std.testing.expectError(error.InvalidVersion, semver.Version.parse("0.15"));
    try std.testing.expectError(error.InvalidVersion, semver.Version.parse("0.15.02"));
    try std.testing.expectError(error.InvalidVersion, semver.Version.parse("0.15.2-"));
    try std.testing.expectError(error.InvalidVersion, semver.Version.parse("0.15.2+"));
}
