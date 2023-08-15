//! CouchDB authentication

const std = @import("std");
const Snorlax = @import("Snorlax.zig");

/// Response of a (cookie) authentication request
pub const CookieAuthenticationResponse = struct {
    /// Operation status
    ok: bool,
    /// Username
    name: []const u8,
    /// List of user roles
    roles: []const []const u8,
};

/// Payload for an authentication request
pub const CookieAuthenticationRequest = struct {
    name: []const u8,
    password: []const u8,
};

pub fn requestCookie(client: *Snorlax) !void {
    const _uri = try client.allocBuildUri("_session");
    defer client.allocator.free(_uri);
    const uri = std.Uri.parse(_uri) catch unreachable;

    const _args = CookieAuthenticationRequest{
        .name = client.authentication.name,
        .password = client.authentication.password,
    };
    const args = try std.json.stringifyAlloc(client.allocator, _args, .{});
    defer client.allocator.free(args);

    var req = client.client.request(.POST, uri, .{ .allocator = client.allocator }, .{}) catch |err| {
        std.log.err("requestCookie: unable to establish connection to '{s}' ({any})", .{
            _uri,
            err,
        });
        return error.ConnectionFailure;
    };
    defer req.deinit();

    try req.headers.append("Content-Type", "application/json");
    req.transfer_encoding = .chunked;
    try req.start();
    try req.writeAll(args);
    try req.finish();
    try req.wait();

    if (req.response.status == .ok) {
        if (req.response.headers.getFirstValue("Set-Cookie")) |_cookie| {
            if (client.authentication.cookie != null) {
                // Free old cookie
                client.allocator.free(client.authentication.cookie.?);
            }

            // Set new authentication cookie
            client.authentication.cookie = try client.allocator.dupe(u8, _cookie);
        } else {
            std.log.err("requestCookie: missing authorization cookie in headers", .{});
            return error.MissingAuthorizationCookie;
        }
    } else {
        std.log.err("requestCookie: authentication failed for {s}. Please verify your credentials", .{
            client.authentication.name,
        });
        return error.AuthenticationFailure;
    }
}
