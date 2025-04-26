const std = @import("std");
const utils = @import("common/utils.zig");
const shared = @import("common/shared.zig");
const configLoader = @import("common/config.zig");

fn start() anyerror!void {
    const allocator = std.heap.page_allocator;

    const homeDirectoryPath = try std.process.getEnvVarOwned(allocator, "HOME");

    const config = try configLoader.loadConfig(allocator, homeDirectoryPath);
    try shared.stdout.print("database path: {s}\n", .{config.databasePath});

    const path = try utils.expandPath(allocator, config.databasePath, homeDirectoryPath);
    defer allocator.free(path);

    try shared.stdout.print("resolved database path: {s}\n", .{path});
}

pub fn main() !void {
    start() catch |err| switch (err) {
        error.SafeExitError => std.process.exit(1),
        else => return err,
    };
}
