const std = @import("std");

const Snorlax = @import("Snorlax.zig");
const Error = @import("Error.zig");
const request = @import("request.zig").request;

pub const Response = struct {
    /// Document ID
    id: []const u8,
    /// Revision MVCC token
    rev: []const u8,

    pub fn deinit(self: *const @This(), a: std.mem.Allocator) void {
        a.free(self.id);
        a.free(self.rev);
    }
};

/// Returns document by the specified docid from the specified db.
pub fn read(
    client: *Snorlax,
    comptime T: type,
    db: []const u8,
    docid: []const u8,
    allocator: std.mem.Allocator,
) !T {
    std.log.info("read: reading document with id {s} from {s}", .{ docid, db });

    var path = try std.fmt.allocPrint(client.allocator, "{s}/{s}", .{ db, docid });
    defer client.allocator.free(path);

    var req = try request(client, .GET, path, null);
    defer req.deinit();

    if (req.response.status == .ok or req.response.status == .not_modified) {
        var mem = try req.reader().readAllAlloc(client.allocator, 8192);
        defer client.allocator.free(mem);
        std.log.info("read: document found", .{});
        std.log.info("{s}", .{mem});

        var parsed_struct = try std.json.parseFromSliceLeaky(T, allocator, mem, .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        });
        return parsed_struct;
    } else {
        if (req.response.status == .bad_request) {
            std.log.err("The format of the request or revision was invalid", .{});
            return error.InvalidFormat;
        } else if (req.response.status == .unauthorized) {
            std.log.err("Read permission required", .{});
            return error.Unauthorized;
        } else if (req.response.status == .not_found) {
            std.log.err("Document not found", .{});
            return error.NotFound;
        }
        return error.Failure;
    }
}

pub fn update(
    client: *Snorlax,
    db: []const u8,
    doc: anytype,
    allocator: ?std.mem.Allocator,
) !?Response {
    //const T = @TypeOf(doc);
    //const TInf = @typeInfo(T);

    var id: ?[]const u8 = doc._id;
    //switch (TInf) {
    //    .Struct => |S| {
    //        inline for (S.fields) |Field| {
    //            if (std.mem.eql(u8, "_id", Field.name)) {
    //                id = if (doc._id) |_id| _id else return error.Invalid;
    //                break;
    //            }
    //        }
    //    },
    //    else => {
    //        std.log.err("update: data type is not a struct", .{});
    //        return error.InvalidDataType;
    //    },
    //}
    //if (id == null) {
    //    std.log.err("update: id field missing", .{});
    //    return error.MissingField;
    //}

    std.log.info("update: update document with id {s} for {s}", .{ id.?, db });

    var path = try std.fmt.allocPrint(client.allocator, "{s}/{s}", .{ db, id.? });
    defer client.allocator.free(path);

    const args = try std.json.stringifyAlloc(client.allocator, doc, .{
        .emit_null_optional_fields = false,
    });
    defer client.allocator.free(args);

    var req = try request(client, .PUT, path, args);
    defer req.deinit();

    if (req.response.status == .created or req.response.status == .accepted) {
        std.log.info("update: document successfully updated", .{});

        if (allocator) |a| {
            var mem = try req.reader().readAllAlloc(client.allocator, 8192);
            defer client.allocator.free(mem);

            var parsed_struct = try std.json.parseFromSliceLeaky(Response, a, mem, .{
                .ignore_unknown_fields = true,
                .allocate = .alloc_always,
            });

            return parsed_struct;
        }
        return null;
    } else {
        if (req.response.status == .bad_request) {
            std.log.err("update: Invalid request body or parameters", .{});
            return error.InvalidFormat;
        } else if (req.response.status == .unauthorized) {
            std.log.err("update: Write privileges required", .{});
            return error.Unauthorized;
        } else if (req.response.status == .not_found) {
            std.log.err("update: Specified database or document ID doesn’t exists", .{});
            return error.NotFound;
        } else if (req.response.status == .conflict) {
            std.log.err("update: Document with the specified ID already exists or specified revision is not latest for target document", .{});
            return error.Conflict;
        }

        return error.Failure;
    }
}

pub fn delete(
    client: *Snorlax,
    db: []const u8,
    docid: []const u8,
    rev: []const u8,
    allocator: ?std.mem.Allocator,
) !?Response {
    std.log.info("delete: Deleting document with id {s} from {s}", .{ docid, db });

    var path = try std.fmt.allocPrint(client.allocator, "{s}/{s}?rev={s}", .{ db, docid, rev });
    defer client.allocator.free(path);

    var req = try request(client, .DELETE, path, null);
    defer req.deinit();

    if (req.response.status == .ok or req.response.status == .accepted) {
        if (req.response.status == .ok) {
            std.log.info("delete: Document with id {s} successfully removed", .{docid});
        } else {
            std.log.info("delete: Requset for document with id {s} accepted, but changes are not yet stored on disk", .{docid});
        }

        if (allocator) |a| {
            var mem = try req.reader().readAllAlloc(client.allocator, 8192);
            defer client.allocator.free(mem);

            var parsed_struct = try std.json.parseFromSliceLeaky(Response, a, mem, .{
                .ignore_unknown_fields = true,
                .allocate = .alloc_always,
            });

            return parsed_struct;
        }
        return null;
    } else {
        if (req.response.status == .bad_request) {
            std.log.err("delete: Invalid request body or parameters", .{});
            return error.InvalidFormat;
        } else if (req.response.status == .unauthorized) {
            std.log.err("delete: Write permission required", .{});
            return error.Unauthorized;
        } else if (req.response.status == .not_found) {
            std.log.err("delete: Specified database or document ID doesn’t exists", .{});
            return error.NotFound;
        } else if (req.response.status == .conflict) {
            std.log.err("delete: Specified revision is not latest for target document", .{});
            return error.Conflict;
        }

        return error.Failure;
    }
}
