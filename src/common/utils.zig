const std = @import("std");

pub fn expandPath(allocator: std.mem.Allocator, path: []const u8, homeDirectoryPath: []const u8) ![]const u8 {
    if (std.mem.startsWith(u8, path, "~")) {
        return try std.mem.concat(allocator, u8, &.{ homeDirectoryPath, path[1..] });
    } else {
        return try allocator.dupe(u8, path);
    }
}
