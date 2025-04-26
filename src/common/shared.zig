const std = @import("std");

// pub const SafeExitError = error{SafeExitError};

pub const stdout = std.io.getStdOut().writer();
pub const stderr = std.io.getStdErr().writer();
pub const stdin = std.io.getStdIn().reader();
