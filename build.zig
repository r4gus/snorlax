const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const snorlax_module = b.addModule("snorlax", .{
        .source_file = .{ .path = "src/main.zig" },
        .dependencies = &.{},
    });

    try b.modules.put(b.dupe("snorlax"), snorlax_module);

    const lib = b.addStaticLibrary(.{
        .name = "snorlax",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Examples
    var examples = Examples.init(b, snorlax_module, optimize);
    examples.install(b);

    //const authenticator = b.addExecutable(.{
    //    .name = "connecting",
    //    .root_source_file = .{ .path = "examples/connecting.zig" },
    //    .target = target,
    //    .optimize = optimize,
    //});
    //authenticator.addModule("snorlax", snorlax_module);
    //b.installArtifact(authenticator);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build test`
    // This will evaluate the `test` step rather than the default, which is "install".
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}

fn root() []const u8 {
    return comptime (std.fs.path.dirname(@src().file) orelse ".") ++ "/";
}

pub const Examples = struct {
    connecting: *std.Build.LibExeObjStep,

    pub fn init(b: *std.Build, module: *std.Build.Module, optimize: std.builtin.OptimizeMode) Examples {
        var ret: Examples = undefined;
        inline for (@typeInfo(Examples).Struct.fields) |field| {
            const path = comptime root() ++ "examples/" ++ field.name ++ ".zig";

            @field(ret, field.name) = b.addExecutable(.{
                .name = field.name,
                .root_source_file = .{ .path = path },
                .optimize = optimize,
            });
            @field(ret, field.name).addModule("snorlax", module);
        }

        return ret;
    }

    pub fn install(examples: *Examples, b: *std.Build) void {
        inline for (@typeInfo(Examples).Struct.fields) |field| {
            b.installArtifact(@field(examples, field.name));
        }
    }
};
