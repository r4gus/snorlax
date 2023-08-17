//! Client handler

const std = @import("std");
const authentication = @import("authentication.zig");

const Allocator = std.mem.Allocator;
const Client = std.http.Client;
const Uri = std.Uri;
const Cookie = @import("cookie.zig").Cookie;
const database = @import("database.zig");

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
    cookie: ?Cookie = null,
    /// Time the cookie was set
    cookie_ts: i64 = 0,
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
    try self.checkCookie();

    return self;
}

pub fn deinit(self: *Self) void {
    if (self.authentication.cookie) |*cookie| {
        cookie.deinit();
    }
    self.authentication.cookie = null;
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

pub fn checkCookie(self: *Self) !void {
    // Request a new cookie if required
    if (self.authentication.cookie) |cookie| {
        if (cookie.max_age) |max_age| {
            if (std.time.timestamp() - self.authentication.cookie_ts >= max_age) {
                // Time is up, request a new cookie
                std.log.info("authentication cookie has expired; requesting new cookie", .{});
                try authentication.requestCookie(self);
            }
        }
    } else {
        std.log.info("no authentication cookie set; requesting new cookie", .{});
        try authentication.requestCookie(self);
    }
}

/// Create a new database with the given `name`
pub fn createDatabase(self: *Self, name: []const u8) !void {
    self.checkCookie() catch {};
    return try database.createDatabase(self, name);
}

/// Delete the database specified by `name`
pub fn deleteDatabase(self: *Self, name: []const u8) !void {
    self.checkCookie() catch {};
    return try database.deleteDatabase(self, name);
}

/// Delete the database specified by `name`
pub fn createDocument(self: *Self, name: []const u8, obj: anytype) !void {
    self.checkCookie() catch {};
    return try database.createDocument(self, name, obj);
}
