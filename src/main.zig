const std = @import("std");
const testing = std.testing;
const net = std.net;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    try stdout.print("Logs from your program will appear here!\n", .{});

    const address = try net.Address.resolveIp("127.0.0.1", 4221);
    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    const conn = try listener.accept();
    // Buffer for input stream

    // buf = GET /index.html HTTP/1.1
    var buf: [1024]u8 = undefined;
    _ = try conn.stream.read(buf[0..]);
    var linesIter = std.mem.splitScalar(u8, &buf, '\n');

    // You can iterate over the lines with something like:
    var line_index: usize = 0;
    var header_line: []const u8 = undefined;
    while (linesIter.next()) |line| {
        if (line_index == 0) {
            header_line = line[0..];
        }
        line_index += 1;
    }

    // Split on space ' '
    var it = std.mem.splitScalar(u8, header_line, ' ');

    // Safely retrieve the tokens
    _ = it.next() orelse "missing method";
    const path = it.next() orelse "missing path";
    _ = it.next() orelse "missing protocol";

    if (std.mem.eql(u8, path, "/index.html") or std.mem.eql(u8, path, "/")) {
        _ = try conn.stream.write("HTTP/1.1 200 OK\r\n\r\n");
    } else if (std.mem.startsWith(u8, path, "/echo/")) {
        const message = path[6..];
        const length = message.len;

        // Allocate enough space to hold the decimal representation of `length`
        var length_str: [4]u8 = undefined;
        _ = try std.fmt.bufPrint(&length_str, "{d}", .{length});

        var bytes_written: u8 = 0;
        for (length_str) |byte| {
            if (byte <= '9' and byte >= '0') {
                bytes_written += 1;
            } else {
                break;
            }
        }

        // Write the length of the message
        const length_slice = length_str[0..bytes_written];
        std.debug.print("length: {s}\n", .{length_slice});

        _ = try conn.stream.write("HTTP/1.1 200 OK\r\n");
        _ = try conn.stream.write("Content-Type: text/plain\r\n");
        _ = try conn.stream.write("Content-Length: ");
        _ = try conn.stream.write(length_slice);
        _ = try conn.stream.write("\r\n\r\n");
        _ = try conn.stream.write(message);
    } else {
        _ = try conn.stream.write("HTTP/1.1 404 Not Found\r\n\r\n");
    }
}
