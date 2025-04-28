const std = @import("std");
const utils = @import("common/utils.zig");
const shared = @import("common/shared.zig");
const device = @import("keyboard/device.zig");
const filter = @import("keyboard/filter.zig");
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

    var timeWindowStart = std.time.milliTimestamp();
    var charactersSeen: f64 = 0.0;
    var previousWPM: f64 = 0.0;

    var previousCharacter: u16 = 0;
    var repetitionCounter: usize = 0;

    var buffer: [24]u8 = undefined;
    while (true) {
        _ = try deviceFeed.read(&buffer);
        const event = try parser.parseKeyboardEvent(buffer);

        if (event.value != 1) continue;
        if (!filter.isPrintableKey(event.code)) continue;

        if (event.code == previousCharacter) {
            repetitionCounter += 1;
            if (repetitionCounter > 5) {
                continue;
            }
        } else {
            repetitionCounter = 0;
            previousCharacter = event.code;
        }

        charactersSeen += 1;

        const currentTime = std.time.milliTimestamp();
        const durationMilliseconds: f64 = @floatFromInt(currentTime - timeWindowStart);
        const durationSeconds: f64 = durationMilliseconds / 1000.0;

        const charactersPerSecond: f64 = charactersSeen / durationSeconds;
        const wordsPerMinute: f64 = (charactersPerSecond * 60) / @as(f64, @floatFromInt(config.assumeAverageWordSize));
        try shared.stdout.print("{d} wpm\n", .{previousWPM});

        if (durationMilliseconds > @as(f64, @floatFromInt(config.timeWindow))) {
            timeWindowStart = std.time.milliTimestamp();
            charactersSeen = 0.0;
            previousWPM = wordsPerMinute;
        }
    }
}

pub fn main() !void {
    start() catch |err| switch (err) {
        error.SafeExitSuccess => std.process.exit(0),
        error.SafeExitError => std.process.exit(1),
        else => return err,
    };
}
