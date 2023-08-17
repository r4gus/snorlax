const std = @import("std");

const Snorlax = @import("Snorlax.zig");
const requestCookie = @import("authentication.zig").requestCookie;

/// Make a request with an optional payload
///
/// This will return the request struct containing the response
/// after completion or an error otherwise.
pub fn request(
    client: *Snorlax,
    method: std.http.Method,
    path: []const u8,
    payload: ?[]const u8,
) !std.http.Client.Request {
    // Build uri for request
    const _uri = try client.allocBuildUri(path);
    defer client.allocator.free(_uri);
    const uri = std.Uri.parse(_uri) catch |err| {
        std.log.err("invalid URI {s} ({any})", .{ _uri, err });
        return err;
    };

    // Create request
    var req = client.client.request(method, uri, .{ .allocator = client.allocator }, .{}) catch |err| {
        std.log.err("unable to establish connection to '{s}' ({any})", .{
            _uri,
            err,
        });
        return error.ConnectionFailure;
    };
    errdefer req.deinit();

    if (client.authentication.cookie) |cookie| {
        const cookie_value = try cookie.stringify(client.allocator);
        defer client.allocator.free(cookie_value);

        try req.headers.append("Cookie", cookie_value);
    }

    if (payload) |_| {
        try req.headers.append("Content-Type", "application/json");
        req.transfer_encoding = .chunked;
    }

    try req.start();

    if (payload) |p| {
        try req.writeAll(p);
        try req.finish();
    }

    try req.wait();

    return req;
}
