//! RFC2109 Cookie Syntax

const std = @import("std");

/// RFC2109 Cookie
///
/// Cookies are submitted by the server using the `Set-Cookie` header
/// and they can be provided to the server using the `Cookie` header.
pub const Cookie = struct {
    /// Name of the cookie
    name: []const u8,
    /// Value of the cookie
    value: []const u8,
    /// Optional comment, e.g. the intended use of a cookie
    comment: ?[]const u8 = null,
    /// Optional domain for which the cookie is valid
    domain: ?[]const u8 = null,
    /// Optional lifetime of the cookie in seconds
    max_age: ?usize = null,
    /// Optional subset of URLs to which tis cookie applies
    path: ?[]const u8 = null,
    /// Optional secure attribute (with no value)
    secure: ?bool = null,
    /// Decimal integer that identifies to which version of the
    /// state management specification the cookie conforms.
    version: usize,
    allocator: std.mem.Allocator,

    /// Deinitialize this struct
    pub fn deinit(self: *const @This()) void {
        self.allocator.free(self.name);
        self.allocator.free(self.value);
        if (self.comment) |v| {
            self.allocator.free(v);
        }
        if (self.domain) |v| {
            self.allocator.free(v);
        }
        if (self.path) |v| {
            self.allocator.free(v);
        }
    }

    /// Parse a cookie string returned by a server into a Cookie struct
    pub fn parse(in: []const u8, allocator: std.mem.Allocator) !@This() {
        var i: usize = 0;
        var j: usize = 0;
        var version_found: bool = false;

        while (j < in.len and in[j] != '=' and in[j] != ';' and in[j] != ' ') : (j += 1) {}
        if (in[j] != '=') return error.Malformed;
        var k = in[i..j];
        j += 1;
        i = j;

        while (j < in.len and in[j] != '=' and in[j] != ';' and in[j] != ' ') : (j += 1) {}
        if (in[j] != ';') return error.Malformed;
        var v = in[i..j];
        j += 1;
        if (in[j] == ' ') j += 1;
        i = j;

        var self = @This(){
            .name = try allocator.dupe(u8, k),
            .value = try allocator.dupe(u8, v),
            .version = undefined,
            .allocator = allocator,
        };
        errdefer self.deinit();

        while (true) {
            if (j >= in.len) break;
            while (j < in.len and in[j] != '=' and in[j] != ';') : (j += 1) {}
            k = in[i..j];
            j += 1;
            i = j;

            if (j < in.len and in[j] == ';') {
                if (std.mem.eql(u8, "Secure", k)) {
                    self.secure = true;
                }
                continue;
            }

            if (j >= in.len) break;
            while (j < in.len and in[j] != ';') : (j += 1) {}
            v = in[i..j];
            j += 1;
            if (in[j] == ' ') j += 1;
            i = j;

            if (std.mem.eql(u8, "Comment", k) and self.comment == null) {
                self.comment = try allocator.dupe(u8, v);
            } else if (std.mem.eql(u8, "Domain", k) and self.domain == null) {
                self.domain = try allocator.dupe(u8, v);
            } else if (std.mem.eql(u8, "Max-Age", k) and self.max_age == null) {
                self.max_age = try std.fmt.parseInt(usize, v, 10);
            } else if (std.mem.eql(u8, "Path", k) and self.path == null) {
                self.path = try allocator.dupe(u8, v);
            } else if (std.mem.eql(u8, "Version", k)) {
                self.version = try std.fmt.parseInt(usize, v, 10);
                version_found = true;
            }
        }

        if (!version_found) return error.Malformed;
        return self;
    }

    /// Create a cookie string
    pub fn stringify(self: *const @This(), allocator: std.mem.Allocator) ![]const u8 {
        var ret = std.ArrayList(u8).init(allocator);
        var writer = ret.writer();

        try writer.print("$Version={d}; {s}={s}", .{
            self.version,
            self.name,
            self.value,
        });
        if (self.path) |path| {
            try writer.print("; $Path={s}", .{path});
        }
        if (self.domain) |domain| {
            try writer.print("; $Domain={s}", .{domain});
        }

        return try ret.toOwnedSlice();
    }
};

test "parse cookie #1" {
    const allocator = std.testing.allocator;

    const cookie = try Cookie.parse("AuthSession=YWRtaW46NjRERTFEM0E6GcJ5S_VKUNOihqqwnNFiVMoMLr7T0Knn2-bFaYTsz7U; Version=1; Expires=Thu, 17-Aug-2023 13:24:34 GMT; Max-Age=600; Path=/; HttpOnly", allocator);
    defer cookie.deinit();

    try std.testing.expectEqualStrings("AuthSession", cookie.name);
    try std.testing.expectEqualStrings("YWRtaW46NjRERTFEM0E6GcJ5S_VKUNOihqqwnNFiVMoMLr7T0Knn2-bFaYTsz7U", cookie.value);
    try std.testing.expectEqual(@as(usize, @intCast(1)), cookie.version);
    try std.testing.expectEqual(@as(usize, @intCast(600)), cookie.max_age.?);
    try std.testing.expectEqualStrings("/", cookie.path.?);
}

test "invalid cookie #1" {
    const allocator = std.testing.allocator;

    try std.testing.expectError(error.Malformed, Cookie.parse("AuthSessionYWRtaW46NjRERTFEM0E6GcJ5S_VKUNOihqqwnNFiVMoMLr7T0Knn2-bFaYTsz7U; Version=1; Expires=Thu, 17-Aug-2023 13:24:34 GMT; Max-Age=600; Path=/; HttpOnly", allocator));
}

test "invalid cookie #2" {
    const allocator = std.testing.allocator;

    try std.testing.expectError(error.Malformed, Cookie.parse("AuthSession=YWRtaW46NjRERTFEM0E6GcJ5S_VKUNOihqqwnNFiVMoMLr7T0Knn2-bFaYTsz7U Version=1; Expires=Thu, 17-Aug-2023 13:24:34 GMT; Max-Age=600; Path=/; HttpOnly", allocator));
}

test "stringify cookie #1" {
    const allocator = std.testing.allocator;

    const cookie = try Cookie.parse("AuthSession=YWRtaW46NjRERTFEM0E6GcJ5S_VKUNOihqqwnNFiVMoMLr7T0Knn2-bFaYTsz7U; Version=1; Expires=Thu, 17-Aug-2023 13:24:34 GMT; Max-Age=600; Path=/; HttpOnly", allocator);
    defer cookie.deinit();

    const s = try cookie.stringify(allocator);
    defer allocator.free(s);

    try std.testing.expectEqualStrings("$Version=1; AuthSession=YWRtaW46NjRERTFEM0E6GcJ5S_VKUNOihqqwnNFiVMoMLr7T0Knn2-bFaYTsz7U; $Path=/", s);
}
