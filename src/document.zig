const std = @import("std");

const Snorlax = @import("Snorlax.zig");
const Error = @import("Error.zig");
const request = @import("request.zig").request;

/// Returns document by the specified docid from the specified db.
pub fn read(
    client: *Snorlax,
    comptime T: type,
    db: []const u8,
    docid: []const u8,
    allocator: std.mem.Allocator,
) !T {
    std.log.info("read: reading document with id {s} form {s}", .{ docid, db });

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
        } else if (req.response.status == .unauthorized) {
            std.log.err("Read permission required", .{});
        } else if (req.response.status == .not_found) {
            std.log.err("Document not found", .{});
        }

        return error.Failed;
    }
}
