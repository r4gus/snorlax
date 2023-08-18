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

pub const ExecutionStatistic = struct {
    total_keys_examined: usize,
    total_docs_examined: usize,
    total_quorum_docs_examined: usize,
    results_returned: usize,
    execution_time_ms: f64,
};

pub const FindRequest = struct {
    /// JSON object describing criteria used to select documents.
    selector: []const u8,
    limit: ?usize = null,
    skip: ?usize = null,
    /// JSON array following sort syntax
    sort: ?[]const []const u8 = null,
    /// JSON array specifying which fields of each object should be returned.
    fields: ?[]const []const u8 = null,
    execution_stats: bool = false,
};

/// Create a response struct for the given tpye `T`
pub fn FindResponse(comptime T: type) type {
    return struct {
        /// Array of documents matching the search. In each matching document,
        /// the fields specified in the fields part of the request body are
        /// listed, along with their values.
        docs: []const T,
        /// Execution warnings
        warning: ?[]const u8 = null,
        /// Execution statistics
        execution_stats: ?ExecutionStatistic = null,
        /// An opaque string used for paging
        bookmark: ?[]const u8 = null,

        pub fn deinit(self: *const @This(), a: std.mem.Allocator) void {
            if (comptime std.meta.trait.hasFn("deinit")(T)) {
                for (self.docs) |d| {
                    d.deinit(a);
                }
            }
            if (self.warning != null) a.free(self.warning.?);
            if (self.bookmark != null) a.free(self.bookmark.?);
        }
    };
}

pub fn find(
    client: *Snorlax,
    dbname: []const u8,
    comptime T: type,
    obj: anytype,
    allocator: std.mem.Allocator,
) !FindResponse(T) {
    // TODO: enforce naiming rules

    std.log.info("find: query object within {s}", .{dbname});

    const args = try std.json.stringifyAlloc(client.allocator, obj, .{
        .emit_null_optional_fields = false,
    });
    defer client.allocator.free(args);

    std.log.info("{s}", .{args});

    var path = try std.fmt.allocPrint(client.allocator, "{s}/_find", .{dbname});
    defer client.allocator.free(path);

    var req = try request(client, .POST, path, args);
    defer req.deinit();

    if (req.response.status == .ok) {
        var mem = try req.reader().readAllAlloc(client.allocator, 8192);
        defer client.allocator.free(mem);
        std.log.info("find: request successful", .{});
        std.log.info("{s}", .{mem});

        const TResp = FindResponse(T);
        var parsed_struct = try std.json.parseFromSliceLeaky(TResp, allocator, mem, .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        });
        return parsed_struct;
    } else {
        if (req.response.status == .bad_request) {
            std.log.err("Invalid request", .{});
        } else if (req.response.status == .unauthorized) {
            std.log.err("Read permission required", .{});
        } else if (req.response.status == .not_found) {
            std.log.err("Database doesn’t exist", .{});
        } else if (req.response.status == .internal_server_error) {
            std.log.err("Query execution error", .{});
        }

        return error.Failed;
    }
}
