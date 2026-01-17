const std = @import("std");
const c = @import("c.zig");
const engine_mod = @import("engine.zig");
const renderer_mod = @import("renderer.zig");
const input_mod = @import("input.zig");
const audio_mod = @import("audio.zig");
const settings_mod = @import("settings.zig");
const tenebris = @import("tenebris.zig");

const TetrisEngine = engine_mod.TetrisEngine;
const GameState = engine_mod.GameState;
const Renderer = renderer_mod.Renderer;
const InputHandler = input_mod.InputHandler;
const AudioPlayer = audio_mod.AudioPlayer;
const Settings = settings_mod.Settings;

const WINDOW_WIDTH = renderer_mod.WINDOW_WIDTH;
const WINDOW_HEIGHT = renderer_mod.WINDOW_HEIGHT;

// Global state for callbacks
var global_game: ?*TetrisEngine = null;
var global_audio: ?*AudioPlayer = null;
var global_settings: ?*Settings = null;
var global_fullscreen: bool = false;
var global_window_width: i32 = WINDOW_WIDTH;
var global_window_height: i32 = WINDOW_HEIGHT;
var global_saved_x: i32 = 0;
var global_saved_y: i32 = 0;
var global_saved_width: i32 = WINDOW_WIDTH;
var global_saved_height: i32 = WINDOW_HEIGHT;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Load settings
    var settings = Settings.load(allocator);
    std.debug.print("Loaded high score from file: {d}\n", .{settings.high_score});

    // Initialize game components
    // Zig 0.16+ API: Use std.posix.gettimeofday() or std.c.time()
    const time_c = @cImport(@cInclude("time.h"));
    const seed = @as(u64, @intCast(time_c.time(null)));
    var game = TetrisEngine.init(seed);
    game.setHighScore(settings.high_score);
    std.debug.print("Set game.high_score to: {d}\n", .{game.high_score});

    // Initialize GLFW
    if (c.glfwInit() == 0) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        return;
    }
    defer c.glfwTerminate();

    // Create window (decode obfuscated window title)
    const window_title_obf = tenebris.ObfuscatedString.init("Tetrix", tenebris.Tenebris.DEFAULT_KEY);
    var title_buf: [32]u8 = undefined;
    const window_title_slice = window_title_obf.value(&title_buf);
    // GLFW needs null-terminated C string
    var title_cstr: [32:0]u8 = undefined;
    @memset(&title_cstr, 0);
    @memcpy(title_cstr[0..window_title_slice.len], window_title_slice);
    const window = c.glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, &title_cstr, null, null);
    if (window == null) {
        std.debug.print("Failed to create window\n", .{});
        return;
    }
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1); // Enable vsync

    // Setup OpenGL
    setupGL();

    var renderer = Renderer.init();
    var input = InputHandler.init();
    var audio = AudioPlayer.init();
    audio.start();
    defer audio.deinit();

    audio.setEnabled(settings.music_enabled);
    global_fullscreen = settings.is_fullscreen;

    // Set global pointers for callbacks
    global_game = &game;
    global_audio = &audio;
    global_settings = &settings;

    // Set callbacks
    _ = c.glfwSetKeyCallback(window, keyCallback);
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    // Apply fullscreen if saved
    if (settings.is_fullscreen) {
        if (window) |win| {
            toggleFullscreen(win);
        }
    }

    // Timing
    var last_time = c.glfwGetTime();

    // Start music
    audio.play();

    // Main loop
    while (c.glfwWindowShouldClose(window) == 0) {
        const current_time = c.glfwGetTime();
        const delta_time = current_time - last_time;
        last_time = current_time;

        // Poll events
        c.glfwPollEvents();

        // Handle input
        // Note: M key toggle is handled in key callback, not here
        // This just reads the current state for the input handler
        var music_enabled = audio.isEnabled();
        input.update(&game, delta_time, window, &music_enabled, &global_fullscreen, &global_window_width, &global_window_height, settings.use_controller);
        // Only update if input handler actually changed it (not for M key which uses toggle())
        if (music_enabled != audio.isEnabled()) {
            audio.setEnabled(music_enabled);
        }

        // Update renderer state
        renderer.use_controller = input.isUsingController(settings.use_controller);
        renderer.music_enabled = audio.isEnabled();

        // Update game logic
        game.update(delta_time);

        // Update audio
        if (game.state == .playing) {
            // std.debug.print("Game state: PLAYING - enabling audio\n", .{});
            audio.play();
        } else {
            // std.debug.print("Game state: NOT PLAYING - disabling audio\n", .{});
            audio.stop();
        }
        audio.update();

        // Render
        renderer.render(&game, delta_time);

        // Swap buffers
        c.glfwSwapBuffers(window);

        // Update high score if needed
        if (game.score > settings.high_score) {
            std.debug.print("Updating high score: {d} -> {d}\n", .{ settings.high_score, game.score });
            settings.high_score = game.score;
            settings.save(allocator);
        }

        // Also sync game.high_score with settings.high_score (in case game.high_score was updated elsewhere)
        if (settings.high_score > game.high_score) {
            std.debug.print("Syncing game.high_score: {d} -> {d}\n", .{ game.high_score, settings.high_score });
            game.setHighScore(settings.high_score);
        }
    }

    // Save settings on exit
    settings.music_enabled = audio.isEnabled();
    settings.is_fullscreen = global_fullscreen;
    settings.use_controller = global_settings.?.use_controller;
    // Make sure we save the correct high score (use game.high_score if it's higher)
    if (game.high_score > settings.high_score) {
        std.debug.print("Exit: game.high_score ({d}) > settings.high_score ({d}), updating\n", .{ game.high_score, settings.high_score });
        settings.high_score = game.high_score;
    }
    std.debug.print("Saving settings on exit: high_score={d}\n", .{settings.high_score});
    settings.save(allocator);
}

fn setupGL() void {
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);

    // Set up orthographic projection
    c.glMatrixMode(c.GL_PROJECTION);
    c.glLoadIdentity();
    c.glOrtho(0, @floatFromInt(WINDOW_WIDTH), @floatFromInt(WINDOW_HEIGHT), 0, -1, 1);

    c.glMatrixMode(c.GL_MODELVIEW);
    c.glLoadIdentity();

    c.glClearColor(20.0 / 255.0, 20.0 / 255.0, 30.0 / 255.0, 1.0);
}

fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void {
    _ = scancode;
    _ = mods;

    if (action != c.GLFW_PRESS) return;

    if (global_game) |game| {
        switch (key) {
            c.GLFW_KEY_UP, c.GLFW_KEY_W => {
                _ = game.rotate();
            },
            c.GLFW_KEY_SPACE => {
                _ = game.hardDrop();
            },
            c.GLFW_KEY_ESCAPE => {
                game.togglePause();
            },
            c.GLFW_KEY_R => {
                if (game.state == .game_over) {
                    game.reset();
                }
            },
            c.GLFW_KEY_M => {
                if (global_audio) |audio| {
                    std.debug.print("Main: M key pressed - toggling music\n", .{});
                    audio.toggle();
                }
            },
            67 => { // 'C'
                if (global_settings) |s| {
                    s.use_controller = !s.use_controller;
                }
            },
            c.GLFW_KEY_F11 => {
                if (window) |win| {
                    toggleFullscreen(win);
                }
            },
            else => {},
        }
    }
}

fn toggleFullscreen(window: *c.GLFWwindow) void {
    global_fullscreen = !global_fullscreen;

    if (global_fullscreen) {
        // Save current window position and size
        c.glfwGetWindowPos(window, &global_saved_x, &global_saved_y);
        c.glfwGetWindowSize(window, &global_saved_width, &global_saved_height);

        // Get primary monitor
        const monitor = c.glfwGetPrimaryMonitor();
        const mode = c.glfwGetVideoMode(monitor);

        // Set fullscreen
        c.glfwSetWindowMonitor(window, monitor, 0, 0, mode.*.width, mode.*.height, mode.*.refreshRate);
    } else {
        // Restore windowed mode
        c.glfwSetWindowMonitor(window, null, global_saved_x, global_saved_y, global_saved_width, global_saved_height, 0);
    }
}

fn framebufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    _ = window;
    global_window_width = width;
    global_window_height = height;

    c.glViewport(0, 0, width, height);

    // Update projection to maintain aspect ratio
    c.glMatrixMode(c.GL_PROJECTION);
    c.glLoadIdentity();

    // Calculate scaling to maintain aspect ratio
    const target_aspect: f32 = @as(f32, @floatFromInt(WINDOW_WIDTH)) / @as(f32, @floatFromInt(WINDOW_HEIGHT));
    const window_aspect: f32 = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));

    if (window_aspect > target_aspect) {
        // Window is wider than target - add black bars on sides
        const scale = @as(f32, @floatFromInt(height)) / @as(f32, @floatFromInt(WINDOW_HEIGHT));
        const scaled_width = @as(f32, @floatFromInt(WINDOW_WIDTH)) * scale;
        const offset = (@as(f32, @floatFromInt(width)) - scaled_width) / 2.0;
        c.glOrtho(-offset / scale, @as(f32, @floatFromInt(WINDOW_WIDTH)) + offset / scale, @floatFromInt(WINDOW_HEIGHT), 0, -1, 1);
    } else {
        // Window is taller than target - add black bars on top/bottom
        const scale = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(WINDOW_WIDTH));
        const scaled_height = @as(f32, @floatFromInt(WINDOW_HEIGHT)) * scale;
        const offset = (@as(f32, @floatFromInt(height)) - scaled_height) / 2.0;
        c.glOrtho(0, @floatFromInt(WINDOW_WIDTH), @as(f32, @floatFromInt(WINDOW_HEIGHT)) + offset / scale, -offset / scale, -1, 1);
    }

    c.glMatrixMode(c.GL_MODELVIEW);
    c.glLoadIdentity();
}
