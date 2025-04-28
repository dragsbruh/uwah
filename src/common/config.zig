const std = @import("std");
const utils = @import("utils.zig");
const shared = @import("shared.zig");

pub const configPathFromHome = ".config/uwah/config.zon";

pub const Config = struct {
    pruneAfter: usize, // use 0 to disable pruning
    timeWindow: usize,
    databasePath: []const u8,
    inputDevice: ?[]const u8, // undefined to auto detect
    assumeAverageWordSize: usize,
};

const defaultConfiguration: Config = .{ .databasePath = "~/.local/share/uwah/", .timeWindow = 5000, .pruneAfter = 0, .inputDevice = undefined, .assumeAverageWordSize = 5 };

pub fn loadConfig(allocator: std.mem.Allocator, homeDirectoryPath: []u8) !Config {
    var homeDirectory = try std.fs.openDirAbsolute(homeDirectoryPath, .{});
    defer homeDirectory.close();

    const configFile = homeDirectory.openFile(configPathFromHome, .{}) catch |err| switch (err) {
        std.fs.File.OpenError.FileNotFound => {
            try shared.stderr.print("warning: config file was not present, populating with sensible defaults. (~/{s})\n", .{configPathFromHome});
            const configFileDirectory = std.fs.path.dirname(configPathFromHome) orelse unreachable;
            try homeDirectory.makePath(configFileDirectory);

            const file = try homeDirectory.createFile(configPathFromHome, .{});
            defer file.close();

            try std.zon.stringify.serialize(defaultConfiguration, .{}, file.writer());
            try file.writeAll("\n");

            var config = defaultConfiguration;
            config.databasePath = try utils.expandPath(allocator, defaultConfiguration.databasePath, homeDirectoryPath);
            try homeDirectory.makePath(config.databasePath);

            return config;
        },
        else => {
            return err;
        },
    };
    defer configFile.close();

    const configBytes = try configFile.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(configBytes);

    const configBytesNullTerminated = try allocator.alloc(u8, configBytes.len + 1);

    std.mem.copyForwards(u8, configBytesNullTerminated[0..configBytes.len], configBytes);
    configBytesNullTerminated[configBytes.len] = 0;

    const configBytesProperNullTerminated: [:0]const u8 = configBytesNullTerminated[0..configBytes.len :0];

    var status: std.zon.parse.Status = .{};
    var parsedConfiguration = std.zon.parse.fromSlice(Config, allocator, configBytesProperNullTerminated, &status, .{ .ignore_unknown_fields = true }) catch |err| switch (err) {
        error.ParseZon => {
            try shared.stdout.print("error: there was an error parsing config file, is the .zon syntax and the schema correct?\n", .{});
            try status.format("", .{}, shared.stderr);
            return error.SafeExitError;
        },
        else => {
            return err;
        },
    };

    parsedConfiguration.databasePath = try utils.expandPath(allocator, parsedConfiguration.databasePath, homeDirectoryPath);
    try homeDirectory.makePath(parsedConfiguration.databasePath);

    if (parsedConfiguration.assumeAverageWordSize == 0) {
        try shared.stdout.print("error: the configured value for assumeAverageWordSize cannot be zero. recommended value is 5. (~/{s})\n", .{configPathFromHome});
        return error.SafeExitError;
    }

    return parsedConfiguration;
}
