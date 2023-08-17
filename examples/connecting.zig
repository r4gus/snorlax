const std = @import("std");
const snorlax = @import("snorlax");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    var client = try snorlax.Snorlax.init("127.0.0.1", 5984, "admin", "fido", allocator);
    defer client.deinit();

    std.debug.print("cookie: {any}\n", .{client.authentication.cookie.?});
}
