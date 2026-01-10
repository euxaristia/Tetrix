const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // Option to set custom executable name (for obfuscated builds)
    const exe_name_option = b.option([]const u8, "name", "Executable name") orelse "tetrix";

    const exe = b.addExecutable(.{
        .name = exe_name_option,
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
    
    const glfw_include_path = glfw_dep.path("include");
    
    // Add GLFW include path so headers can be found
    exe.root_module.addIncludePath(glfw_include_path);

    // Link platform-specific libraries
    const target_os = builtin.target.os.tag;
    switch (target_os) {
        .windows => {
            // Windows-specific linker optimizations (matching Package.swift)
            // These reduce binary size and improve obfuscation
            // Note: LTO is enabled by default for release builds in Zig 0.16+
            // ReleaseSmall already includes dead code elimination
            
            // Build as Windows GUI application (no console window)
            // This matches Package.swift's /SUBSYSTEM:WINDOWS
            exe.subsystem = .Windows;
            // Entry point is handled automatically by Zig
            
            // For Windows: Compile GLFW C sources directly into the executable
            // This avoids needing a separate static library build step
            // TODO: Update for Zig 0.16+ API when Windows cross-compilation is needed
            // For now, Windows builds will need GLFW DLLs or a different approach
            exe.root_module.addIncludePath(glfw_dep.path("deps"));
            
            // Link Windows audio libraries for WASAPI
            exe.linkSystemLibrary("ole32");  // COM initialization
            exe.linkSystemLibrary("avrt");   // Multimedia Class Scheduler Service (for low-latency audio)
            // Windows doesn't need math library (it's part of libc)
        },
        .linux => {
            // Link GLFW (available via system package manager)
            exe.linkSystemLibrary("glfw");
            // Link OpenGL
            exe.linkSystemLibrary("GL");
            // Link ALSA for audio
            exe.linkSystemLibrary("asound");
        },
        .macos => {
            // macOS: Link OpenGL framework
            // TODO: Update for Zig 0.16+ API
            // exe.linkFramework("OpenGL"); // API changed
            // macOS doesn't need math library
            // macOS uses CoreAudio, not ALSA
        },
        else => {
            // For other platforms
            // TODO: Update for Zig 0.16+ API
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
