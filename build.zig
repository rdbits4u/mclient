const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void
{
    // build options
    const do_strip = b.option(bool, "strip", "Strip the executabes")
            orelse false;
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // mclient

    const mclient = myAddExecutable(b, "mclient", target, optimize, do_strip);
    mclient.linkLibC();
    mclient.linkFramework("Cocoa");
    mclient.linkFramework("QuartzCore");
    mclient.addIncludePath(b.path("../common"));
    mclient.addIncludePath(b.path("../rdpc/include"));
    mclient.addIncludePath(b.path("../svc/include"));
    mclient.addIncludePath(b.path("../cliprdr/include"));
    mclient.addIncludePath(b.path("../rdpsnd/include"));
    mclient.addIncludePath(b.path("../librfxcodec/include"));
    mclient.addIncludePath(b.path("../librlecodec/include"));
    mclient.addIncludePath(b.path("../drdynvc/include"));
    mclient.addIncludePath(b.path("../edisp/include"));
    mclient.addCSourceFiles(.{ .files = mclient_sources, } );
    mclient.addObjectFile(b.path("../rdpc/zig-out/lib/librdpc.a"));
    mclient.addObjectFile(b.path("../svc/zig-out/lib/libsvc.a"));
    mclient.addObjectFile(b.path("../cliprdr/zig-out/lib/libcliprdr.a"));
    mclient.addObjectFile(b.path("../rdpsnd/zig-out/lib/librdpsnd.a"));
    mclient.addObjectFile(b.path("../librfxcodec/zig-out/lib/librfxdecode.a"));
    mclient.addObjectFile(b.path("../librlecodec/zig-out/lib/librledecode.a"));
    mclient.addObjectFile(b.path("../drdynvc/zig-out/lib/libdrdynvc.a"));
    mclient.addObjectFile(b.path("../edisp/zig-out/lib/libedisp.a"));
    b.installArtifact(mclient);
}

//*****************************************************************************
fn myAddExecutable(b: *std.Build, name: []const u8,
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
        do_strip: bool) *std.Build.Step.Compile
{
    if ((builtin.zig_version.major == 0) and (builtin.zig_version.minor < 15))
    {
        return b.addExecutable(.{
            .name = name,
            .target = target,
            .optimize = optimize,
            .strip = do_strip,
        });
    }
    return b.addExecutable(.{
        .name = name,
        .root_module = b.addModule(name, .{
            .target = target,
            .optimize = optimize,
            .strip = do_strip,
        }),
    });
}

const mclient_sources = &.{
    "src/mclient.m",
    "src/mclient_view.m",
    "src/mclient_window.m",
    "src/mclient_app_delegate.m",
    "src/rdpc_session.m",
    "src/mclient_log.m",
};