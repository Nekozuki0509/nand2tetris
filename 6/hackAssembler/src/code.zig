const std = @import("std");

pub fn dest(mnemonic: []const u8) u3 {
    var ans: u3 = 0;
    if (std.mem.findScalar(u8, mnemonic, 'A') != null) ans |= 1 << 2;
    if (std.mem.findScalar(u8, mnemonic, 'D') != null) ans |= 1 << 1;
    if (std.mem.findScalar(u8, mnemonic, 'M') != null) ans |= 1 << 0;

    return ans;
}

pub fn comp(mnemonic: []const u8) u7 {
    const has_d = std.mem.findScalar(u8, mnemonic, 'D') != null;
    const has_y = std.mem.findAny(u8, mnemonic, "AM") != null;

    var ans: u7 = 0;
    if (std.mem.findScalar(u8, mnemonic, 'M') != null) ans |= 1 << 6;
    if (!has_d) ans |= 1 << 5;
    if (!has_y) ans |= 1 << 3;
    if (std.mem.findAny(u8, mnemonic, "01+-") != null) ans |= 1 << 1;
    if (std.mem.findAny(u8, mnemonic, "1!-|") != null) ans |= 1 << 0;
    if (std.mem.find(u8, mnemonic, "-1") != null) ans ^= 1 << 0;
    if (std.mem.findScalar(u8, mnemonic, '|') != null or std.mem.find(u8, mnemonic, "+1") != null or std.mem.eql(u8, mnemonic, "1")) {
        ans |= 1 << 2 | 1 << 4;
    } else if (!std.mem.eql(u8, mnemonic, "0") and std.mem.findAny(u8, mnemonic, "+&") == null) {
        ans |= if (has_d and (!has_y or mnemonic[0] != 'D')) 1 << 2 else 1 << 4;
    }

    return ans;
}

pub fn jump(mnemonic: []const u8) u3 {
    var ans: u3 = 0;
    if (std.mem.findAny(u8, mnemonic, "LNM") != null) ans |= 1 << 2;
    if (std.mem.findAny(u8, mnemonic, "EM") != null) ans |= 1 << 1;
    if (std.mem.eql(u8, mnemonic, "JNE")) ans ^= 1 << 1;
    if (std.mem.findAny(u8, mnemonic, "GNM") != null) ans |= 1 << 0;

    return ans;
}
