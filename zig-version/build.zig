const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "tetrix",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    // Link GLFW (cross-platform)
    exe.linkSystemLibrary("glfw");

    // Link OpenGL and platform-specific libraries
    const target_os = target.result.os.tag;
    switch (target_os) {
        .windows => {
            exe.linkSystemLibrary("opengl32");
            // Windows doesn't need math library (it's part of libc)
            // Windows uses different audio APIs (DirectSound/WASAPI), not ALSA
        },
        .linux => {
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("m"); // Math library for Linux
            exe.linkSystemLibrary("asound"); // ALSA for Linux
        },
        .macos => {
            exe.linkFramework("OpenGL");
            // macOS doesn't need math library
            // macOS uses CoreAudio, not ALSA
        },
        else => {
            // For other platforms, try generic names
            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("m");
        },
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}
