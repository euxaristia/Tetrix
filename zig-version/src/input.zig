const std = @import("std");
const c = @import("c.zig");
const engine_mod = @import("engine.zig");
const TetrisEngine = engine_mod.TetrisEngine;
const GameState = engine_mod.GameState;

pub const InputHandler = struct {
    // Key repeat timing
    left_pressed: bool = false,
    right_pressed: bool = false,
    down_pressed: bool = false,

    left_hold_time: f64 = 0,
    right_hold_time: f64 = 0,
    down_hold_time: f64 = 0,

    left_repeat_timer: f64 = 0,
    right_repeat_timer: f64 = 0,
    down_repeat_timer: f64 = 0,

    // Joystick state
    joystick_present: bool = false,
    use_controller: bool = false,
    joy_left_pressed: bool = false,
    joy_right_pressed: bool = false,
    joy_down_pressed: bool = false,
    joy_up_pressed: bool = false,
    joy_a_pressed: bool = false,
    joy_start_pressed: bool = false,
    joy_select_pressed: bool = false,

    const INITIAL_DELAY: f64 = 0.12; // 120ms
    const REPEAT_INTERVAL: f64 = 0.025; // 25ms
    const DOWN_REPEAT_INTERVAL: f64 = 0.02; // 20ms
    const JOY_INITIAL_DELAY: f64 = 0.15;
    const JOY_REPEAT_INTERVAL: f64 = 0.03;

    pub fn init() InputHandler {
        return .{};
    }

    pub fn update(self: *InputHandler, game: *TetrisEngine, delta_time: f64, window: ?*c.GLFWwindow, music_enabled: *bool, fullscreen: *bool, window_width: *i32, window_height: *i32) void {
        if (window == null) return;
        const win = window.?;

        // Check joystick
        self.joystick_present = c.glfwJoystickPresent(c.GLFW_JOYSTICK_1) == c.GLFW_TRUE;
        if (self.joystick_present) {
            self.handleJoystick(game, delta_time, music_enabled);
        }

        // Handle key repeats
        self.handleKeyRepeats(game, delta_time, win);

        // Handle single-press keys through callback
        _ = fullscreen;
        _ = window_width;
        _ = window_height;
    }

    fn handleKeyRepeats(self: *InputHandler, game: *TetrisEngine, delta_time: f64, window: *c.GLFWwindow) void {
        // Left key
        const left_state = c.glfwGetKey(window, c.GLFW_KEY_LEFT) == c.GLFW_PRESS or
            c.glfwGetKey(window, c.GLFW_KEY_A) == c.GLFW_PRESS;

        if (left_state) {
            if (!self.left_pressed) {
                self.left_pressed = true;
                self.left_hold_time = 0;
                self.left_repeat_timer = 0;
                _ = game.moveLeft();
            } else {
                self.left_hold_time += delta_time;
                if (self.left_hold_time >= INITIAL_DELAY) {
                    self.left_repeat_timer += delta_time;
                    if (self.left_repeat_timer >= REPEAT_INTERVAL) {
                        self.left_repeat_timer = 0;
                        _ = game.moveLeft();
                    }
                }
            }
        } else {
            self.left_pressed = false;
        }

        // Right key
        const right_state = c.glfwGetKey(window, c.GLFW_KEY_RIGHT) == c.GLFW_PRESS or
            c.glfwGetKey(window, c.GLFW_KEY_D) == c.GLFW_PRESS;

        if (right_state) {
            if (!self.right_pressed) {
                self.right_pressed = true;
                self.right_hold_time = 0;
                self.right_repeat_timer = 0;
                _ = game.moveRight();
            } else {
                self.right_hold_time += delta_time;
                if (self.right_hold_time >= INITIAL_DELAY) {
                    self.right_repeat_timer += delta_time;
                    if (self.right_repeat_timer >= REPEAT_INTERVAL) {
                        self.right_repeat_timer = 0;
                        _ = game.moveRight();
                    }
                }
            }
        } else {
            self.right_pressed = false;
        }

        // Down key (soft drop)
        const down_state = c.glfwGetKey(window, c.GLFW_KEY_DOWN) == c.GLFW_PRESS or
            c.glfwGetKey(window, c.GLFW_KEY_S) == c.GLFW_PRESS;

        if (down_state) {
            if (!self.down_pressed) {
                self.down_pressed = true;
                self.down_hold_time = 0;
                self.down_repeat_timer = 0;
                _ = game.softDrop();
            } else {
                self.down_hold_time += delta_time;
                if (self.down_hold_time >= INITIAL_DELAY) {
                    self.down_repeat_timer += delta_time;
                    if (self.down_repeat_timer >= DOWN_REPEAT_INTERVAL) {
                        self.down_repeat_timer = 0;
                        _ = game.softDrop();
                    }
                }
            }
        } else {
            self.down_pressed = false;
        }
    }

    fn handleJoystick(self: *InputHandler, game: *TetrisEngine, delta_time: f64, music_enabled: *bool) void {
        var axes_count: c_int = 0;
        const axes_ptr = c.glfwGetJoystickAxes(c.GLFW_JOYSTICK_1, &axes_count);
        if (axes_ptr == null) return;

        var buttons_count: c_int = 0;
        const buttons_ptr = c.glfwGetJoystickButtons(c.GLFW_JOYSTICK_1, &buttons_count);
        if (buttons_ptr == null) return;

        const axes = axes_ptr[0..@intCast(axes_count)];
        const buttons = buttons_ptr[0..@intCast(buttons_count)];

        // D-Pad (axes 6 and 7 on many controllers, or buttons)
        const dpad_x: f32 = if (axes_count > 6) axes[6] else 0.0;
        const dpad_y: f32 = if (axes_count > 7) axes[7] else 0.0;

        // Alternative: use left stick
        const stick_x: f32 = if (axes_count > 0) axes[0] else 0.0;
        const stick_y: f32 = if (axes_count > 1) axes[1] else 0.0;

        const left = dpad_x < -0.5 or stick_x < -0.5;
        const right = dpad_x > 0.5 or stick_x > 0.5;
        const down = dpad_y > 0.5 or stick_y > 0.5;
        const up = dpad_y < -0.5 or stick_y < -0.5;

        // Handle D-pad left
        if (left) {
            self.use_controller = true;
            if (!self.joy_left_pressed) {
                self.joy_left_pressed = true;
                self.left_hold_time = 0;
                self.left_repeat_timer = 0;
                _ = game.moveLeft();
            } else {
                self.left_hold_time += delta_time;
                if (self.left_hold_time >= JOY_INITIAL_DELAY) {
                    self.left_repeat_timer += delta_time;
                    if (self.left_repeat_timer >= JOY_REPEAT_INTERVAL) {
                        self.left_repeat_timer = 0;
                        _ = game.moveLeft();
                    }
                }
            }
        } else {
            self.joy_left_pressed = false;
        }

        // Handle D-pad right
        if (right) {
            self.use_controller = true;
            if (!self.joy_right_pressed) {
                self.joy_right_pressed = true;
                self.right_hold_time = 0;
                self.right_repeat_timer = 0;
                _ = game.moveRight();
            } else {
                self.right_hold_time += delta_time;
                if (self.right_hold_time >= JOY_INITIAL_DELAY) {
                    self.right_repeat_timer += delta_time;
                    if (self.right_repeat_timer >= JOY_REPEAT_INTERVAL) {
                        self.right_repeat_timer = 0;
                        _ = game.moveRight();
                    }
                }
            }
        } else {
            self.joy_right_pressed = false;
        }

        // Handle D-pad down (soft drop)
        if (down) {
            self.use_controller = true;
            if (!self.joy_down_pressed) {
                self.joy_down_pressed = true;
                self.down_hold_time = 0;
                self.down_repeat_timer = 0;
                _ = game.softDrop();
            } else {
                self.down_hold_time += delta_time;
                if (self.down_hold_time >= JOY_INITIAL_DELAY) {
                    self.down_repeat_timer += delta_time;
                    if (self.down_repeat_timer >= DOWN_REPEAT_INTERVAL) {
                        self.down_repeat_timer = 0;
                        _ = game.softDrop();
                    }
                }
            }
        } else {
            self.joy_down_pressed = false;
        }

        // Handle D-pad up / A button (rotate)
        const a_button = buttons_count > 0 and buttons[0] == c.GLFW_PRESS;
        const x_button = buttons_count > 2 and buttons[2] == c.GLFW_PRESS;

        if (up or a_button or x_button) {
            self.use_controller = true;
            if (!self.joy_up_pressed and !self.joy_a_pressed) {
                self.joy_up_pressed = up;
                self.joy_a_pressed = a_button or x_button;
                _ = game.rotate();
            }
        } else {
            self.joy_up_pressed = false;
            self.joy_a_pressed = false;
        }

        // Start button (pause)
        const start_button = buttons_count > 7 and buttons[7] == c.GLFW_PRESS;
        if (start_button) {
            self.use_controller = true;
            if (!self.joy_start_pressed) {
                self.joy_start_pressed = true;
                game.togglePause();
            }
        } else {
            self.joy_start_pressed = false;
        }

        // Select button (restart on game over)
        const select_button = buttons_count > 6 and buttons[6] == c.GLFW_PRESS;
        if (select_button) {
            self.use_controller = true;
            if (!self.joy_select_pressed) {
                self.joy_select_pressed = true;
                if (game.state == .game_over) {
                    game.reset();
                }
            }
        } else {
            self.joy_select_pressed = false;
        }

        // M button mapping (Y button - index 3 on many controllers)
        const y_button = buttons_count > 3 and buttons[3] == c.GLFW_PRESS;
        if (y_button) {
            music_enabled.* = !music_enabled.*;
        }
    }

    pub fn isUsingController(self: *const InputHandler) bool {
        return self.use_controller and self.joystick_present;
    }
};
