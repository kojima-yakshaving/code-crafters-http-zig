const std = @import("std");
const testing = std.testing;
const network = @import("network.zig");
const request_handler = @import("request_handler.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    try stdout.print("Logs from your program will appear here!\n", .{});

    var listener = try network.startListener(4221);
    defer listener.deinit();

    const conn = try listener.accept();
    try request_handler.handleRequest(conn);
}
