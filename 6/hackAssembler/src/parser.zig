const std = @import("std");

const Parser = @This();

content: []u8,
lines: std.ArrayList(Instruction),
now: usize = 0,

pub const Instruction = union(enum) {
    A_INSTRUCTION: []const u8,
    C_INSTRUCTION: struct { dest: []const u8, comp: []const u8, jump: []const u8 },
    L_INSTRUCTION: []const u8,
};
pub const InstructionType = std.meta.Tag(Instruction);

pub fn init(gpa: std.mem.Allocator, io: std.Io, path: []const u8) !Parser {
    const content = try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .unlimited);
    errdefer gpa.free(content);

    var list: std.ArrayList(Instruction) = .empty;
    errdefer list.deinit(gpa);

    var it = std.mem.tokenizeAny(u8, content, "\r\n");
    while (it.next()) |raw| {
        const line = std.mem.trim(u8, if (std.mem.indexOf(u8, raw, "//")) |i| raw[0..i] else raw, &std.ascii.whitespace);
        if (line.len == 0) continue;

        switch (line[0]) {
            '@' => try list.append(gpa, .{ .A_INSTRUCTION = line[1..] }),
            '(' => try list.append(gpa, .{ .L_INSTRUCTION = line[1 .. line.len - 1] }),
            else => {
                const start = if (std.mem.findScalar(u8, line, '=')) |i| i + 1 else 0;
                const end = std.mem.findScalar(u8, line, ';') orelse line.len;
                try list.append(gpa, .{ .C_INSTRUCTION = .{
                    .dest = line[0..start],
                    .comp = line[start..end],
                    .jump = if (end < line.len) line[end + 1 ..] else "",
                } });
            },
        }
    }

    return .{ .content = content, .lines = list };
}

pub fn deinit(self: *Parser, gpa: std.mem.Allocator) void {
    self.lines.deinit(gpa);
    gpa.free(self.content);
}

pub fn hasMoreLines(self: *Parser) bool {
    return self.now < self.lines.items.len;
}

pub fn advance(self: *Parser) void {
    std.debug.assert(self.hasMoreLines());
    self.now += 1;
}

pub fn reset(self: *Parser) void {
    self.now = 0;
}

pub fn instructionType(self: *Parser) InstructionType {
    return std.meta.activeTag(self.lines.items[self.now - 1]);
}

pub fn symbol(self: *Parser) []const u8 {
    return switch (self.lines.items[self.now - 1]) {
        .A_INSTRUCTION, .L_INSTRUCTION => |s| s,
        .C_INSTRUCTION => unreachable,
    };
}

pub fn dest(self: *Parser) []const u8 {
    return self.lines.items[self.now - 1].C_INSTRUCTION.dest;
}

pub fn comp(self: *Parser) []const u8 {
    return self.lines.items[self.now - 1].C_INSTRUCTION.comp;
}

pub fn jump(self: *Parser) []const u8 {
    return self.lines.items[self.now - 1].C_INSTRUCTION.jump;
}
