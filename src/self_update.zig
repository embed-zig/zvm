const std = @import("std");

pub fn isHomebrewManaged(allocator: std.mem.Allocator) !bool {
    const exe = try std.fs.selfExePathAlloc(allocator);
    defer allocator.free(exe);

    return std.mem.indexOf(u8, exe, "/Cellar/") != null or
        std.mem.indexOf(u8, exe, "/Homebrew/") != null or
        std.mem.indexOf(u8, exe, "/opt/homebrew/") != null;
}

pub fn updateMessage(allocator: std.mem.Allocator, current_version: []const u8) ![]const u8 {
    if (try isHomebrewManaged(allocator)) {
        return allocator.dupe(u8, "zvm appears to be managed by Homebrew. Use: brew upgrade zvm\n");
    }

    return std.fmt.allocPrint(allocator,
        \\zvm {s} can be updated with the project installer once release artifacts exist:
        \\  curl -fsSL https://raw.githubusercontent.com/embed-zig/zvm/main/install.sh | sh
        \\
    , .{current_version});
}
