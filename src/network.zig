const std = @import("std");
const net = std.net;

pub fn startListener(port: u16) !net.Server {
    const address = try net.Address.resolveIp("127.0.0.1", port);
    return try address.listen(.{ .reuse_address = true });
}
