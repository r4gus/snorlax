const std = @import("std");

const Snorlax = @import("Snorlax.zig");
const Error = @import("Error.zig");
const request = @import("request.zig").request;

/// Create a new database
pub fn createDatabase(client: *Snorlax, name: []const u8) !void {
    // TODO: enforce naiming rules

    std.log.info("createDatabase: requesting creation of database with the name {s}", .{name});

    var req = try request(client, .PUT, name, null);
    defer req.deinit();

    if (req.response.status == .created or req.response.status == .accepted) {
        std.log.info("createDatabase: database creation successful", .{});
    } else {
        if (req.response.status == .bad_request) {
            std.log.err("Invalid database name", .{});
        } else if (req.response.status == .unauthorized) {
            std.log.err("CouchDB Server Administrator privileges required", .{});
        } else if (req.response.status == .precondition_failed) {
            std.log.err("Database already exists", .{});
        }

        return error.Failed;
    }
}

/// Delete the specified database
pub fn deleteDatabase(client: *Snorlax, name: []const u8) !void {
    // TODO: enforce naiming rules

    std.log.info("deleteDatabase: requesting the deletion of database with the name {s}", .{name});

    var req = try request(client, .DELETE, name, null);
    defer req.deinit();

    if (req.response.status == .ok or req.response.status == .accepted) {
        std.log.info("deleteDatabase: database deletion successful", .{});
    } else {
        if (req.response.status == .bad_request) {
            std.log.err("Invalid database name or forgotten document id by accident", .{});
        } else if (req.response.status == .unauthorized) {
            std.log.err("CouchDB Server Administrator privileges required", .{});
        } else if (req.response.status == .not_found) {
            std.log.err("Database doesn’t exist or invalid database name", .{});
        }
        return error.Failed;
    }
}

/// Creates a new document in the specified database,
pub fn createDocument(client: *Snorlax, name: []const u8, obj: anytype) !void {
    // TODO: enforce naiming rules

    std.log.info("createDocument: requesting the creation of a document for the database with the name {s}", .{name});

    const args = try std.json.stringifyAlloc(client.allocator, obj, .{
        .emit_null_optional_fields = false,
    });
    defer client.allocator.free(args);

    std.log.info("{s}", .{args});

    var req = try request(client, .POST, name, args);
    defer req.deinit();

    if (req.response.status == .created or req.response.status == .accepted) {
        std.log.info("createDocument: document creation successful", .{});
    } else {
        if (req.response.status == .bad_request) {
            std.log.err("Invalid database name", .{});
        } else if (req.response.status == .unauthorized) {
            std.log.err("Write privileges required", .{});
        } else if (req.response.status == .not_found) {
            std.log.err("Database doesn’t exist", .{});
        } else if (req.response.status == .conflict) {
            std.log.err("A Conflicting Document with same ID already exists", .{});
        }

        return error.Failed;
    }
}
