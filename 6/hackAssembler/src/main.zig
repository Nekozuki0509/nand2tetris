const std = @import("std");
const Parser = @import("parser.zig");
const Code = @import("code.zig");
const SymbolTable = @import("symbolTable.zig");

const _6 = @import("_6");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2 or std.mem.find(u8, args[1], ".asm") == null) {
        std.debug.print("usage: {s} <file.asm>\n", .{args[0]});
        return error.MissingArgument;
    }

    var parser = try Parser.init(init.gpa, init.io, args[1]);
    defer parser.deinit(init.gpa);
    var symbolTable = try SymbolTable.init(init.gpa);
    defer symbolTable.deinit();

    var i: usize = 0;
    while (parser.hasMoreLines()) {
        parser.advance();

        if (parser.instructionType() == .L_INSTRUCTION) {
            try symbolTable.addEntry(parser.symbol(), i);
        } else {
            i += 1;
        }
    }

    parser.reset();

    const file = try std.Io.Dir.cwd().createFile(init.io, try std.fmt.allocPrint(init.arena.allocator(), "{s}.hack", .{args[1][0 .. args[1].len - 4]}), .{});
    defer file.close(init.io);

    var buf: [4096]u8 = undefined;
    var fw = file.writer(init.io, &buf);

    var j: usize = 16;
    while (parser.hasMoreLines()) {
        parser.advance();

        switch (parser.instructionType()) {
            .A_INSTRUCTION => {
                if (std.fmt.parseInt(usize, parser.symbol(), 10) catch null) |num| {
                    try symbolTable.addEntry(try std.fmt.allocPrint(init.arena.allocator(), "{d}", .{num}), num);
                } else if (!symbolTable.contains(parser.symbol())) {
                    try symbolTable.addEntry(parser.symbol(), j);
                    j += 1;
                }

                try fw.interface.print("{b:0>16}\n", .{symbolTable.getAddress(parser.symbol())});
            },
            .C_INSTRUCTION => try fw.interface.print("111{b:0>7}{b:0>3}{b:0>3}\n", .{ Code.comp(parser.comp()), Code.dest(parser.dest()), Code.jump(parser.jump()) }),
            else => {},
        }
    }

    try fw.interface.flush();
}
