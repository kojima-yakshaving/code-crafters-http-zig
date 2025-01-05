const std = @import("std");
const Status = std.http.Status;

pub const Response = struct {
    status: Status,
    headers: ?[]const ResponseHeader,
    body: []const u8,
};

pub const ResponseHeader = struct {
    key: []const u8,
    value: []const u8,
};

pub fn respond(conn: std.net.Server.Connection, response: Response) !void {
    var buf: [1024]u8 = .{0} ** 1024;
    const phrase = response.status.phrase().?;

    // returns printed slice
    const head = try std.fmt.bufPrint(&buf, "HTTP/1.1 {d} {s}\r\n", .{ @intFromEnum(response.status), phrase });
    _ = try conn.stream.write(head);
    const stdout = std.io.getStdOut().writer();
    _ = try stdout.write(head);
    if (response.headers) |headers| {
        std.debug.print("Headers written\n", .{});
        for (headers) |header| {
            _ = try conn.stream.writeAll(header.key);
            _ = try conn.stream.writeAll(": ");
            _ = try conn.stream.writeAll(header.value);
            _ = try conn.stream.write("\r\n");
        }
        std.debug.print("Headers written\n", .{});
    }
    _ = try conn.stream.writeAll("\r\n");
    if (response.body.len == 0) {
        return;
    }
    _ = try conn.stream.write(response.body);
}

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
        try respond(conn, Response{
            .status = Status.ok,
            .headers = null,
            .body = "",
        });
    } else if (std.mem.startsWith(u8, path, "/echo/")) {
        const message = path[6..];
        const length = message.len;

        const result = try std.fmt.bufPrint(&buf, "{d}", .{length});

        const headers = [_]ResponseHeader{
            .{ .key = "Content-Type", .value = "text/plain" },
            .{ .key = "Content-Length", .value = result },
        };
        try respond(conn, Response{
            .status = Status.ok,
            .headers = headers[0..],
            .body = message,
        });
    } else {
        try respond(conn, Response{ .status = Status.not_found, .headers = null, .body = "" });
    }
}
