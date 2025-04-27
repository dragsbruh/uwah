const std = @import("std");
const shared = @import("../common/shared.zig");

const KeyboardEvent = struct {
    sec: u64,
    usec: u64,
    type: u16,
    code: u16,
    value: u48,
};

pub fn parseKeyboardEvent(eventBytes: [24]u8) !KeyboardEvent {
    return KeyboardEvent{
        .sec = littleEndianSegmentsToNumber(u64, u6, eventBytes[0..8]),
        .usec = littleEndianSegmentsToNumber(u64, u6, eventBytes[8..16]),
        .type = littleEndianSegmentsToNumber(u16, u4, eventBytes[16..18]),
        .code = littleEndianSegmentsToNumber(u16, u4, eventBytes[18..20]),
        .value = littleEndianSegmentsToNumber(u48, u6, eventBytes[20..24]),
    };
}

fn littleEndianSegmentsToNumber(comptime ResultNumberType: type, comptime IndexNumberType: type, bytes: []const u8) ResultNumberType {
    var result: ResultNumberType = 0;
    var i: IndexNumberType = 0;
    for (bytes) |byte| {
        result |= @as(ResultNumberType, byte) << (i * 8);
        i += 1;
    }
    return result;
}
