//! This is a basic example on how to connect to a local
//! CouchDB instance.

const std = @import("std");
const snorlax = @import("snorlax");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Meal = struct {
    _id: ?[]const u8 = null,
    _rev: ?[]const u8 = null,
    servings: usize,
    subtitle: []const u8,
    title: []const u8,

    pub fn deinit(self: *const @This(), a: std.mem.Allocator) void {
        if (self._id) |id| {
            a.free(id);
        }
        if (self._rev) |rev| {
            a.free(rev);
        }
        a.free(self.subtitle);
        a.free(self.title);
    }
};

pub fn main() !void {
    // 1. First we have to instanciate a new client by providing a IP address/ URL, the PORT,
    // username, and password.
    var client = try snorlax.Snorlax.init("127.0.0.1", 5984, "admin", "fido", allocator);
    defer client.deinit();

    // 2. Now we delete the test database (if one already exists).
    client.deleteDatabase("fido") catch |err| {
        std.debug.print("database deletion failed ({any})\n", .{err});
    };

    // 3. Next we create a new database with the name fido.
    client.createDatabase("fido") catch |err| {
        std.debug.print("database creation failed ({any})\n", .{err});
    };

    // 4. Create
    const m1 = Meal{
        ._id = "ab39fe0993049b84cfa81acd6ebad09d", // make sure the ID field has the form `_id`
        .servings = 4,
        .subtitle = "Delicious with fresh bread",
        .title = "Fish Stew",
    };

    client.createDocument("fido", m1) catch |err| {
        std.debug.print("document creation failed ({any})\n", .{err});
    };

    // 5. Read
    const m2 = client.read(Meal, "fido", "ab39fe0993049b84cfa81acd6ebad09d", allocator) catch |err| {
        std.debug.print("unable to read document with id {s} ({any})\n", .{
            "ab39fe0993049b84cfa81acd6ebad09d",
            err,
        });
        return;
    };
    defer m2.deinit(allocator);

    std.debug.assert(std.mem.eql(u8, m2._id.?, "ab39fe0993049b84cfa81acd6ebad09d"));
    std.debug.assert(m2.servings == 4);
    std.debug.assert(std.mem.eql(u8, m2.subtitle, "Delicious with fresh bread"));
    std.debug.assert(std.mem.eql(u8, m2.title, "Fish Stew"));

    std.debug.print("id={s}\nservings={d}\nsubtitle={s}\ntitle={s}\n", .{
        m2._id.?,
        m2.servings,
        m2.subtitle,
        m2.title,
    });
}
