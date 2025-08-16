const std = @import("std");

pub fn build(b: *std.Build) void
{
    // build options
    const do_strip = b.option(bool, "strip", "Strip the executabes")
            orelse false;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // mclient
    const mclient = b.addExecutable(.{.name = "mclient",
            .target = target, .optimize = optimize, .strip = do_strip});
    mclient.linkLibC();
    mclient.linkFramework("Cocoa");
    mclient.addIncludePath(b.path("../common"));
    mclient.addIncludePath(b.path("../rdpc/include"));
    mclient.addIncludePath(b.path("../svc/include"));
    mclient.addIncludePath(b.path("../cliprdr/include"));
    mclient.addIncludePath(b.path("../rdpsnd/include"));
    mclient.addIncludePath(b.path("../librfxcodec/include"));
    mclient.addCSourceFiles(.{ .files = mclient_sources, } );
    mclient.addObjectFile(b.path("../rdpc/zig-out/lib/librdpc.dylib"));
    mclient.addObjectFile(b.path("../svc/zig-out/lib/libsvc.dylib"));
    mclient.addObjectFile(b.path("../cliprdr/zig-out/lib/libcliprdr.dylib"));
    mclient.addObjectFile(b.path("../rdpsnd/zig-out/lib/librdpsnd.dylib"));
    mclient.addObjectFile(b.path("../librfxcodec/zig-out/lib/librfxdecode.a"));
    mclient.addLibraryPath(.{.cwd_relative = "../rdpc/zig-out/lib"});
    mclient.addLibraryPath(.{.cwd_relative = "../svc/zig-out/lib"});
    mclient.addLibraryPath(.{.cwd_relative = "../cliprdr/zig-out/lib"});
    mclient.addLibraryPath(.{.cwd_relative = "../rdpsnd/zig-out/lib"});
    b.installArtifact(mclient);
}

const mclient_sources = &.{
    "src/mclient.m",
    "src/mclient_view.m",
    "src/mclient_app_delegate.m",
    "src/rdpc_session.m",
    "src/mclient_log.m",
};