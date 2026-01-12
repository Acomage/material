const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    //Generate LUT
    const gen_exe = b.createModule(.{
        .root_source_file = b.path("src/MaxChromaGen.zig"),
        .target = target,
        .optimize = optimize,
    });

    gen_exe.addIncludePath(b.path("src"));

    const gen = b.addExecutable(.{
        .name = "gen-maxchroma",
        .root_module = gen_exe,
    });
    b.installArtifact(gen);

    const run_gen_cmd = b.addRunArtifact(gen);
    run_gen_cmd.addArg("./src/Hct/MaxChroma.zig");

    // build CLI
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

    exe.step.dependOn(&run_gen_cmd.step);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "运行程序");
    run_step.dependOn(&run_cmd.step);
}
