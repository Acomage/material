const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    exe_mod.linkSystemLibrary("png", .{});
    exe_mod.linkSystemLibrary("turbojpeg", .{});
    exe_mod.addIncludePath(b.path("src"));
    exe_mod.addObjectFile(b.path("src/Extract/futhark/build/extract.o"));
    exe_mod.addObjectFile(b.path("src/Extract/futhark/build/extract.kernels.o"));

    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "运行程序");
    run_step.dependOn(&run_cmd.step);
}
