const std = @import("std");

pub fn handleRequest(conn: std.net.Server.Connection) !void {
    var buf: [1024]u8 = undefined;
    _ = try conn.stream.read(buf[0..]);
    var linesIter = std.mem.splitScalar(u8, &buf, '\n');

    var line_index: usize = 0;
    var header_line: []const u8 = undefined;
    while (linesIter.next()) |line| {
        if (line_index == 0) {
            header_line = line[0..];
        }
        line_index += 1;
    }

    var it = std.mem.splitScalar(u8, header_line, ' ');

    _ = it.next() orelse "missing method";
    const path = it.next() orelse "missing path";
    _ = it.next() orelse "missing protocol";

    if (std.mem.eql(u8, path, "/index.html") or std.mem.eql(u8, path, "/")) {
        _ = try conn.stream.write("HTTP/1.1 200 OK\r\n\r\n");
    } else if (std.mem.startsWith(u8, path, "/echo/")) {
        const message = path[6..];
        const length = message.len;

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
