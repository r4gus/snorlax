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
};

pub fn main() !void {
    // 1. First we have to instanciate a new client by providing a IP address/ URL, the PORT,
    // username, and password.
    var client = try snorlax.Snorlax.init("127.0.0.1", 5984, "admin", "fido", allocator);
    defer client.deinit();

    // 2. If everything goes well, the client will automatically request a cookie
    // from the server.
    std.debug.print("cookie: {any}\n", .{client.authentication.cookie.?});

    // 3. Now we delete the test database (if one already exists).
    client.deleteDatabase("fido") catch |err| {
        std.debug.print("database deletion failed ({any})\n", .{err});
    };

    // 4. Next we create a new database with the name fido.
    std.debug.print("create new database\n", .{});
    client.createDatabase("fido") catch |err| {
        std.debug.print("database creation failed ({any})\n", .{err});
    };

    // 5. We can use structs to create new documents in the database.
    //
    // If we omit the _id field, the database will automatically assign
    // an id to the new document.
    const m1 = Meal{
        .servings = 4,
        .subtitle = "Delicious with fresh bread",
        .title = "Fish Stew",
    };

    // If you want to provide an id make sure that its a string and not an array!
    // (You can for example encode your u8-ID-slice by calling std.fmt.bytesToHex)
    const m2 = Meal{
        ._id = "ab39fe0993049b84cfa81acd6ebad09d",
        .servings = 6,
        .subtitle = "Whats that?",
        .title = "Dead rat",
    };

    // 6. Just pass your struct to the createDocument function to create
    // a new document.
    client.createDocument("fido", m1) catch |err| {
        std.debug.print("document creation failed ({any})\n", .{err});
    };

    client.createDocument("fido", m2) catch |err| {
        std.debug.print("document creation failed ({any})\n", .{err});
    };
}
