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

    while (true) {
        const conn = try listener.accept();

        // Optional: log the new connection
        std.log.info("New connection accepted", .{});

        // Spawn a new thread to handle this connection concurrently.
        // NOTE: The result of 'spawn' is '!Thread', so we 'try' it.
        _ = try std.Thread.spawn(.{}, handleConnection, .{conn});
    }
}

/// Runs in a separate thread to handle the connection.
fn handleConnection(conn: std.net.Server.Connection) !void {

    // Your existing request handling logic:
    try request_handler.handleRequest(conn);

    // Optional: log that the request has completed.
    std.log.info("Connection closed", .{});
}
