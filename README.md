# Snorlax

A __work in progress__ [CouchDB](https://couchdb.apache.org/) client library.

## Getting started

1. Install [Zig](https://ziglang.org/download/) `0.11.0` on your system.
2. Follow the CouchDB [installation instructions](https://docs.couchdb.org/en/stable/install/index.html)
to setup CouchDB on your system.
3. Then check out one of the [examples](examples). After running `zig build` you can find the executables in `zig-out/bin`.

> Note: You have to adjust the examples (e.g. username and password)!

### Adding Snorlax to your application

First add this library as dependency to your `build.zig.zon` file:
```zon
.{
    .name = "your-project",
    .version = 0.0.1,

    .dependencies = .{
        .snorlax = .{
            .url = "https://github.com/r4gus/snorlax/archive/master.tar.gz",
            .hash = "<your hash>",
        }
    },
}
```

> The easiest way to obtain the hash is to leave it blank or enter a wrong hash and then copy the correct
> one from the error message.

Then within your `build.zig`:
```zig
// Fetch the dependency...
const snorlax_dep = b.dependency("snorlax", .{
    .target = target,
    .optimize = optimize,
});
// ...and obtain the module
const snorlax_module = snorlax_dep.module("snorlax");

...

// Add this module to your executable
exe.addModule("snorlax", snorlax_module);
```

After you've added the `snorlax` module to your application, you can import it using
`const snorlax = @import("snorlax");`.

## Overfiew

Currently the library supports the following operations:

* Create a new database by using the `createDatabase` function
* Delete a database (and all its documents) by using the `deleteDatabase` function
* Create a new document by using the `createDocument` function
* Find a document based on _selectors_ by using the `find` function
* Read a specific document by using the `read` function
* Update a existing document by using the `update` function
* Delete a existing document by using the `delete` function

Check out the [examples](examples) folder for an overfiew on how to use the library.
