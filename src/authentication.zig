//! CouchDB authentication

const std = @import("std");
const Snorlax = @import("Snorlax.zig");
const Cookie = @import("cookie.zig").Cookie;
const request = @import("request.zig").request;

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
    std.log.info("requestCookie: requesting authorization cookie", .{});

    const _args = CookieAuthenticationRequest{
        .name = client.authentication.name,
        .password = client.authentication.password,
    };
    const args = try std.json.stringifyAlloc(client.allocator, _args, .{});
    defer client.allocator.free(args);

    var req = try request(client, .POST, "_session", args);
    defer req.deinit();

    if (req.response.status == .ok) {
        if (req.response.headers.getFirstValue("Set-Cookie")) |_cookie| {
            if (client.authentication.cookie != null) {
                // Free old cookie
                client.authentication.cookie.?.deinit();
            }

            // Set new authentication cookie
            client.authentication.cookie = try Cookie.parse(_cookie, client.allocator);
            client.authentication.cookie_ts = std.time.timestamp();
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

    std.log.info("requestCookie: authorization cookie request successful", .{});
}
