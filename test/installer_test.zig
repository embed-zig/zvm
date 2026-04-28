const std = @import("std");
const zpath = @import("zvm-path");

test "zig symlink target uses single bin directory layout" {
    const target = try zpath.zigSymlinkTarget(std.testing.allocator, "0.15.2-esp.r4");
    defer std.testing.allocator.free(target);

    try std.testing.expectEqualStrings("../versions/0.15.2-esp.r4/zig", target);
}
