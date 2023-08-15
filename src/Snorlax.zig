//! Client handler

const std = @import("std");
const authentication = @import("authentication.zig");

const Allocator = std.mem.Allocator;
const Client = std.http.Client;
const Uri = std.Uri;

const Self = @This();

/// The URL or IP address of the CouchDB server
url: []const u8,
/// The port of the CouchDB server (default is 5984)
port: u16 = 5984,
/// TODO: support https
https: ?struct {} = null,
/// Authentication settings
authentication: struct {
    /// Username
    name: []const u8,
    /// Password
    password: []const u8,
    /// Authentication cookie
    cookie: ?[]u8 = null,
},
client: Client,
allocator: Allocator,

pub fn init(
    url: []const u8,
    port: u16,
    name: []const u8,
    password: []const u8,
    allocator: Allocator,
) !Self {
    var self: Self = .{
        .url = url,
        .port = port,
        .client = .{ .allocator = allocator },
        .authentication = .{
            .name = name,
            .password = password,
        },
        .allocator = allocator,
    };
    errdefer self.client.deinit();

    // Request the first cookie. This is a first check to make
    // sure everything works fine.
    try authentication.requestCookie(&self);

    return self;
}

pub fn deinit(self: *Self) void {
    if (self.authentication.cookie != null) {
        self.allocator.free(self.authentication.cookie.?);
    }
    // self.client.deinit(); setfault???
}

pub fn cookieAuthentication(self: *Self) !void {
    _ = self;
}

pub fn allocBuildUri(self: *Self, path: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(self.allocator, "{s}://{s}:{d}/{s}", .{
        if (self.https == null) "http" else "https",
        self.url,
        self.port,
        path,
    });
}
