const std = @import("std");
const shared = @import("../common/shared.zig");
const configLoader = @import("../common/config.zig");

// caller must free the input device path
pub fn getPreferredInputDevice(allocator: std.mem.Allocator, config: configLoader.Config) ![]const u8 {
    if (config.inputDevice != null) {
        const configuredInputDeviceNotNullish = config.inputDevice.?;
        std.fs.accessAbsolute(configuredInputDeviceNotNullish, .{}) catch |err| switch (err) {
            else => {
                try shared.stderr.print("error: the input device specified in config file was not accessible, see all available devices at: uwah devices\n", .{});
                return error.SafeExitError;
            },
        };

        const realInputDevicePath = try std.fs.realpathAlloc(allocator, configuredInputDeviceNotNullish);

        if (!std.mem.startsWith(u8, realInputDevicePath,  "/dev/input/")) {
            try shared.stderr.print("error: the input device specified in config file was not inside /dev/input/ (specified {s})\n", .{realInputDevicePath});
            return error.SafeExitError;
        }

        return realInputDevicePath;
    }

    const devicesPath = try std.fs.openDirAbsolute("/dev/input/by-path/", .{ .iterate = true });

    var walker = try devicesPath.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (std.mem.endsWith(u8, entry.basename, "-kbd")) {
            return try devicesPath.realpathAlloc(allocator, entry.basename);
        }
    }

    try shared.stderr.print("could not autodetect a keyboard device, please manually specify one in config file (~/{s})\n", .{configLoader.configPathFromHome});
    return error.SafeExitError;
}
