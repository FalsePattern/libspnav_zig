const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const x11 = b.option(bool, "x11", "X11 communication mode.") orelse false;
    const magellan = b.option(bool, "magellan", "Include the original Magellan SDK compatibility wrapper. Requires X11.") orelse false;

    if (magellan and !x11) {
        @panic("libspnav magellan compatibility requires x11!");
    }

    const upstream = b.dependency("libspnav", .{});

    const lib = b.addLibrary(.{
        .name = "spnav",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const header = b.addWriteFile("spnav_config.h", genConfigHeader(b, x11));

    lib.step.dependOn(&header.step);

    lib.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = if (magellan) &.{
            "proto.c",
            "spnav.c",
            "spnav_magellan.c",
            "util.c"
        } else &.{
            "proto.c",
            "spnav.c",
            "util.c"
        },
    });
    lib.addIncludePath(header.getDirectory());
    lib.installHeadersDirectory(upstream.path("src"), "", .{
        .include_extensions = if (magellan) &.{
            "proto.h",
            "spnav.h",
            "spnav_magellan.h",
        } else &.{
            "proto.h",
            "spnav.h",
        },
    });
    lib.installHeadersDirectory(header.getDirectory(), "", .{
        .include_extensions = &.{
            "spnav_config.h",
        },
    });
    if (x11) {
        lib.linkSystemLibrary("x11");
    }

    b.installArtifact(lib);
}

fn genConfigHeader(b: *std.Build, x11: bool) []const u8 {
    var result: std.ArrayListUnmanaged(u8) = .empty;
    result.appendSlice(b.allocator, "#ifndef SPNAV_CONFIG_H_\n#define SPNAV_CONFIG_H_\n") catch @panic("OOM");
    if (x11) {
        result.appendSlice(b.allocator, "#define SPNAV_USE_X11\n") catch @panic("OOM");
    }
    result.appendSlice(b.allocator, "#endif /* SPNAV_CONFIG_H_ */\n") catch @panic("OOM");
    return result.toOwnedSlice(b.allocator) catch @panic("OOM");
}
