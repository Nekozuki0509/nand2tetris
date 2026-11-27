const std = @import("std");

const SymbolTable = @This();

map: std.StringHashMap(usize),

pub fn init(gpa: std.mem.Allocator) !SymbolTable {
    var map = std.StringHashMap(usize).init(gpa);
    errdefer map.deinit();

    try map.put("SP", 0);
    try map.put("LCL", 1);
    try map.put("ARG", 2);
    try map.put("THIS", 3);
    try map.put("THAT", 4);
    try map.put("SCREEN", 16384);
    try map.put("KBD", 24576);
    inline for (0..16) |i| try map.put(std.fmt.comptimePrint("R{d}", .{i}), i);

    return .{ .map = map };
}

pub fn deinit(self: *SymbolTable) void {
    self.map.deinit();
}

pub fn addEntry(self: *SymbolTable, symbol: []const u8, address: usize) !void {
    try self.map.put(symbol, address);
}

pub fn contains(self: *SymbolTable, symbol: []const u8) bool {
    return self.map.contains(symbol);
}

pub fn getAddress(self: *SymbolTable, symbol: []const u8) usize {
    return self.map.get(symbol).?;
}
