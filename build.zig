const std = @import("std");

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
    exe.addIncludePath(glfw_include_path);

    // Link platform-specific libraries
    const target_os = target.result.os.tag;
    switch (target_os) {
        .windows => {
            // Windows-specific linker optimizations (matching Package.swift)
            // These reduce binary size and improve obfuscation
            if (optimize != .Debug) {
                // Remove unreferenced functions and data
                exe.want_lto = true; // Link-time optimization (similar to /OPT:REF)
                // Note: Zig's LTO includes dead code elimination similar to /OPT:REF
                // /OPT:ICF (identical COMDAT folding) is handled by LTO
                // /INCREMENTAL:NO is default for release builds in Zig
            }
            
            // Build as Windows GUI application (no console window)
            // This matches Package.swift's /SUBSYSTEM:WINDOWS
            exe.subsystem = .Windows;
            // Entry point is handled automatically by Zig
            
            // For Windows: Compile GLFW C sources directly into the executable
            // This avoids needing a separate static library build step
            exe.root_module.addIncludePath(glfw_dep.path("deps"));
            
            // Common GLFW source files - compile directly into executable
            const glfw_cflags = &.{"-D_GLFW_WIN32"};
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/context.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/init.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/input.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/monitor.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/platform.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/vulkan.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/window.c"), .flags = glfw_cflags });
            
            // Windows-specific source files
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/win32_init.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/win32_joystick.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/win32_module.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/win32_monitor.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/win32_thread.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/win32_time.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/win32_window.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/wgl_context.c"), .flags = glfw_cflags });
            
            // Null context stubs (needed for platform.c)
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/null_init.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/null_joystick.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/null_monitor.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/null_window.c"), .flags = glfw_cflags });
            
            // EGL and OSMesa stubs (optional, but referenced)
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/egl_context.c"), .flags = glfw_cflags });
            exe.addCSourceFile(.{ .file = glfw_dep.path("src/osmesa_context.c"), .flags = glfw_cflags });
            
            exe.linkSystemLibrary("opengl32");
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("user32");
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
