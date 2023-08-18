//! This is a basic example on how to connect to a local
//! CouchDB instance.

const std = @import("std");
const snorlax = @import("snorlax");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Meal = struct {
    _id: ?[]const u8 = null,
    servings: usize,
    subtitle: []const u8,
    title: []const u8,

    pub fn deinit(self: *const @This(), a: std.mem.Allocator) void {
        if (self._id) |id| {
            a.free(id);
        }
        a.free(self.subtitle);
        a.free(self.title);
    }
};

pub fn main() !void {
    // 1. first, lets insert some documents into our db, so we have something to find
    var client = try snorlax.Snorlax.init("127.0.0.1", 5984, "admin", "fido", allocator);
    defer client.deinit();

    client.deleteDatabase("fido") catch |err| {
        std.debug.print("database deletion failed ({any})\n", .{err});
    };

    client.createDatabase("fido") catch |err| {
        std.debug.print("database creation failed ({any})\n", .{err});
    };

    const m1 = Meal{
        .servings = 4,
        .subtitle = "Delicious with fresh bread",
        .title = "Fish Stew",
    };

    const m2 = Meal{
        .servings = 6,
        .subtitle = "Whats that?",
        .title = "Dead rat",
    };

    const m3 = Meal{
        .servings = 3,
        .subtitle = "With buffalo mozzarella",
        .title = "Pizza",
    };

    const m4 = Meal{
        .servings = 9,
        .subtitle = "It's just bread",
        .title = "Bread",
    };

    // 6. Just pass your struct to the createDocument function to create
    // a new document.
    client.createDocument("fido", m1) catch |err| {
        std.debug.print("document creation failed ({any})\n", .{err});
    };

    client.createDocument("fido", m2) catch |err| {
        std.debug.print("document creation failed ({any})\n", .{err});
    };

    client.createDocument("fido", m3) catch |err| {
        std.debug.print("document creation failed ({any})\n", .{err});
    };

    client.createDocument("fido", m4) catch |err| {
        std.debug.print("document creation failed ({any})\n", .{err});
    };

    // The /{db}/_find endpoint expects a request object with atleast
    // a selector (https://docs.couchdb.org/en/stable/api/database/find.html#db-find).
    //
    // The caller is responsible for creating a valid request struct that contains
    // a selector field.
    const X = struct {
        selector: struct {
            servings: struct {
                @"$gt": usize,
            },
        },
    };
    // Let's find all documents that have more than 4 servings.
    const x = X{ .selector = .{ .servings = .{ .@"$gt" = 4 } } };

    // The find function expects the name of the database, the type of document we expect,
    // our request object, and an allocator. As you can see we can't fetch documents of
    // different types right now.
    var r = try client.find("fido", Meal, x, allocator);
    // We have to call deinit on the returned object to free the allocated memory.
    // If the document type (in our case Meal) has a deinit function, this function
    // will be called for each received document.
    defer r.deinit(allocator);

    // Now let's iterate over the received documents and display their name.
    for (r.docs) |d| {
        std.debug.print("{s}\n", .{d.title});
    }
}
