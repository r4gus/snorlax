const std = @import("std");

const Snorlax = @import("Snorlax.zig");
const Error = @import("Error.zig");

/// Create a new database
pub fn createDatabase(client: *Snorlax, name: []const u8) !void {
    // TODO: enforce naiming rules
    _ = client;
    _ = name;
}
