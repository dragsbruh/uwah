const std = @import("std");
const utils = @import("common/utils.zig");
const shared = @import("common/shared.zig");
const device = @import("keyboard/device.zig");
const parser = @import("keyboard/parser.zig");
const configLoader = @import("common/config.zig");

fn start() anyerror!void {
    const allocator = std.heap.page_allocator;

    const homeDirectoryPath = try std.process.getEnvVarOwned(allocator, "HOME");

    const config = try configLoader.loadConfig(allocator, homeDirectoryPath);
    defer allocator.free(config.databasePath);

    const databaseDirectoryPath = try utils.expandPath(allocator, config.databasePath, homeDirectoryPath);
    defer allocator.free(databaseDirectoryPath);

    const inputDevicePath = try device.getPreferredInputDevice(allocator, config);
    defer allocator.free(inputDevicePath);

    const deviceFeed = try std.fs.openFileAbsolute(inputDevicePath, .{});
    defer deviceFeed.close();

    var buffer: [24]u8 = undefined;
    while (true) {
        _ = try deviceFeed.read(&buffer);
        const event = try parser.parseKeyboardEvent(buffer);
        try shared.stdout.print("code:{d} type:{d} value:{d} on time:{d} usec:{d}\n", .{event.code, event.type, event.value, event.sec, event.usec});
    }
}

pub fn main() !void {
    start() catch |err| switch (err) {
        error.SafeExitSuccess => std.process.exit(0),
        error.SafeExitError => std.process.exit(1),
        else => return err,
    };
}
