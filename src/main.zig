const std = @import("std");
const utils = @import("common/utils.zig");
const shared = @import("common/shared.zig");
const configLoader = @import("common/config.zig");

fn start() anyerror!void {
    const allocator = std.heap.page_allocator;

    const homeDirectoryPath = try std.process.getEnvVarOwned(allocator, "HOME");

    const config = try configLoader.loadConfig(allocator, homeDirectoryPath);
    defer allocator.free(config.databasePath);

    const databaseDirectoryPath = try utils.expandPath(allocator, config.databasePath, homeDirectoryPath);
    defer allocator.free(databaseDirectoryPath);
}

pub fn main() !void {
    start() catch |err| switch (err) {
        error.SafeExitError => std.process.exit(1),
        else => return err,
    };
}
