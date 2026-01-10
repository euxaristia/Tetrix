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

    // Get GLFW dependency from build.zig.zon
    const glfw_dep = b.dependency("glfw", .{
        .target = target,
        .optimize = optimize,
    });
    
    // Add GLFW include path so headers can be found
    exe.root_module.addIncludePath(glfw_dep.path("include"));
    exe.addIncludePath(glfw_dep.path("include"));

    // Link platform-specific libraries
    const target_os = target.result.os.tag;
    switch (target_os) {
        .windows => {
            // GLFW source is fetched via build.zig.zon, but needs to be built/linked
            // For now, Windows builds will fail at link time until GLFW is built
            // TODO: Build GLFW from source or link pre-built Windows binaries
            // The GLFW headers are available via glfw_dep.path("include")
            // but the library needs to be compiled and linked
            
            exe.linkSystemLibrary("opengl32");
            // Windows doesn't need math library (it's part of libc)
            // Windows uses different audio APIs (DirectSound/WASAPI), not ALSA
        },
        .linux => {
            // Link GLFW (available via system package manager)
            exe.linkSystemLibrary("glfw");
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
