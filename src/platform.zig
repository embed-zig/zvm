const std = @import("std");
const builtin = @import("builtin");

pub fn currentTargetTag(allocator: std.mem.Allocator) ![]const u8 {
    return std.fmt.allocPrint(allocator, "{s}-{s}", .{ osName(builtin.os.tag), archName(builtin.cpu.arch) });
}

pub fn archiveExtension() []const u8 {
    return if (builtin.os.tag == .windows) ".zip" else ".tar.xz";
}

pub fn osName(tag: std.Target.Os.Tag) []const u8 {
    return switch (tag) {
        .linux => "linux",
        .macos => "macos",
        .windows => "windows",
        .freebsd => "freebsd",
        else => "unknown",
    };
}

pub fn archName(arch: std.Target.Cpu.Arch) []const u8 {
    return switch (arch) {
        .x86_64 => "x86_64",
        .aarch64 => "aarch64",
        .arm => "arm",
        .riscv64 => "riscv64",
        else => "unknown",
    };
}
