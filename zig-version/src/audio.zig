const std = @import("std");
const c = @import("c.zig");

pub const SAMPLE_RATE: u32 = 44100;
const AMPLITUDE: f32 = 20000.0; // Significantly increased amplitude for better volume
const TEMPO_BPM: f32 = 149.0;

// Note frequencies (matching Swift version)
const NOTE_FREQ = struct {
    const C3: f32 = 130.81;
    const D3: f32 = 146.83;
    const E3: f32 = 164.81;
    const F3: f32 = 174.61;
    const G3: f32 = 196.00;
    const A3: f32 = 220.00;
    const B3: f32 = 246.94;
    const C4: f32 = 261.63;
    const D4: f32 = 293.66;
    const E4: f32 = 329.63;
    const F4: f32 = 349.23;
    const G4: f32 = 392.00;
    const A4: f32 = 440.00;
    const B4: f32 = 493.88;
    const C5: f32 = 523.25;
    const D5: f32 = 587.33;
    const E5: f32 = 659.25;
    const F5: f32 = 698.46;
    const G5: f32 = 783.99;
    const A5: f32 = 880.00;
    const B5: f32 = 987.77;
    const E6: f32 = 1318.51;
    const REST: f32 = 0.0;
};

const Note = struct {
    freq: f32,
    duration: f32, // in beats
};

// Complete Korobeiniki melody (Tetris theme) - matching Swift version
// Full Game Boy Type A theme loop
const melody = [_]Note{
    // First phrase (2/4 time, eighth notes and quarter notes)
    .{ .freq = NOTE_FREQ.E5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.5 },
    // Second phrase
    .{ .freq = NOTE_FREQ.A4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 1.5 },
    // Third phrase
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    // Fourth phrase
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.F5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.A5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.G5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.F5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    // Extended section - middle part of the full melody
    .{ .freq = NOTE_FREQ.E5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.5 },
    .{ .freq = NOTE_FREQ.A4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 1.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    // Final phrase leading back to start
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.F5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.A5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.G5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.F5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    // Extended ending for smoother loop - resolves more naturally
    .{ .freq = NOTE_FREQ.G4, .duration = 2.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.B4, .duration = 1.0 },
};

pub const AudioPlayer = struct {
    enabled: std.atomic.Value(bool) = std.atomic.Value(bool).init(true),
    playing: std.atomic.Value(bool) = std.atomic.Value(bool).init(true),
    should_stop: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    audio_thread: ?std.Thread = null,
    mutex: std.Thread.Mutex = .{},

    // Audio state - protected by mutex
    sample_index: u64 = 0,
    note_index: usize = 0,
    note_sample_position: u32 = 0,
    pcm_handle: ?*c.snd_pcm_t = null,
    debug_wrote_after_toggle: bool = false,

    const samples_per_beat: u32 = @intFromFloat(@as(f32, @floatFromInt(SAMPLE_RATE)) * 60.0 / TEMPO_BPM);

    pub fn init() AudioPlayer {
        return AudioPlayer{};
    }
    
    pub fn start(self: *AudioPlayer) void {
        self.startAudioThread();
    }

    fn startAudioThread(self: *AudioPlayer) void {
        self.audio_thread = std.Thread.spawn(.{}, audioThreadFn, .{self}) catch {
            // If thread creation fails, just continue without audio
            return;
        };
    }

    fn audioThreadFn(self: *AudioPlayer) void {
        std.debug.print("Audio thread started!\n", .{});

        // Initialize ALSA in blocking mode within the audio thread
        var handle: ?*c.snd_pcm_t = null;

        // Try multiple ALSA devices to find a working one
        // Prioritize the plughw device that we know works
        std.debug.print("Audio: Trying to open ALSA devices...\n", .{});
        const devices = [_][*:0]const u8{
            "plughw:1,3", // Plug version for NVIDIA HDMI 0 - handles format conversion (WORKING!)
            "plughw:1,7", // Plug version for NVIDIA HDMI 1
            "default",
            "plughw:0,0", // Plug version for HyperX Wireless
            "plughw:2,0", // Plug version for Intel PCH Analog
            "sysdefault:CARD=NVidia", // System default for NVIDIA card
            "front:CARD=NVidia,DEV=3", // Front device for NVIDIA HDMI 0
            "hw:1,3",    // NVIDIA HDMI 0 (DELL G2725D) - from aplay -l
            "hw:1,7",    // NVIDIA HDMI 1
            "hw:0,0",    // HyperX Wireless
            "hw:2,0",    // Intel PCH Analog
        };

        var device_index: usize = 0;
        while (device_index < devices.len) : (device_index += 1) {
            const open_result = c.snd_pcm_open(&handle, devices[device_index], c.SND_PCM_STREAM_PLAYBACK, 0);
            if (open_result == 0) {
                // Successfully opened a device
                std.debug.print("Audio: Successfully opened device: {s}\n", .{devices[device_index]});
                break;
            } else {
                std.debug.print("Audio: Failed to open device {s}: {d}\n", .{devices[device_index], open_result});
            }

            // If we've tried all devices and none worked
            if (device_index == devices.len - 1) {
                std.debug.print("Audio: ERROR - Failed to open ANY audio device!\n", .{});
                std.debug.print("Audio: This usually means ALSA is not properly configured or devices are in use.\n", .{});
                std.debug.print("Audio: Game will continue without audio.\n", .{});
                return; // Exit audio thread gracefully if no devices work
            }

            // If we're on the last device and it failed, clean up and return
            if (device_index == devices.len - 1) {
                std.debug.print("Audio: Failed to open any audio device\n", .{});
                return;
            }
        }

        // Set parameters
        var params: ?*c.snd_pcm_hw_params_t = null;
        _ = c.snd_pcm_hw_params_malloc(&params);
        defer _ = c.snd_pcm_hw_params_free(params);

        _ = c.snd_pcm_hw_params_any(handle, params);
        _ = c.snd_pcm_hw_params_set_access(handle, params, c.SND_PCM_ACCESS_RW_INTERLEAVED);
        _ = c.snd_pcm_hw_params_set_format(handle, params, c.SND_PCM_FORMAT_S16_LE);
        _ = c.snd_pcm_hw_params_set_channels(handle, params, 1);

        var rate: c_uint = SAMPLE_RATE;
        _ = c.snd_pcm_hw_params_set_rate_near(handle, params, &rate, null);

        // Smaller buffer for lower latency
        var buffer_size: c.snd_pcm_uframes_t = 4096;
        _ = c.snd_pcm_hw_params_set_buffer_size_near(handle, params, &buffer_size);

        var period_size: c.snd_pcm_uframes_t = 1024;
        _ = c.snd_pcm_hw_params_set_period_size_near(handle, params, &period_size, null);

        std.debug.print("Audio: Setting ALSA parameters...\n", .{});
        const params_result = c.snd_pcm_hw_params(handle, params);
        if (params_result < 0) {
            std.debug.print("Audio: ERROR - Failed to set ALSA parameters: {d}\n", .{params_result});
            _ = c.snd_pcm_close(handle);
            return;
        }
        std.debug.print("Audio: ALSA parameters set successfully\n", .{});

        if (c.snd_pcm_prepare(handle) < 0) {
            _ = c.snd_pcm_close(handle);
            return;
        }

        {
            self.mutex.lock();
            defer self.mutex.unlock();
            self.pcm_handle = handle;
        }

        // Audio generation loop
        var buffer: [512]i16 = undefined;

        // Track last state for debug output
        var last_enabled: bool = true;
        var last_playing: bool = true;
        
        while (!self.should_stop.load(.acquire)) {
            const enabled = self.enabled.load(.acquire);
            const playing = self.playing.load(.acquire);

            // Debug: Show audio state changes (only when actually changing)
            if (enabled != last_enabled or playing != last_playing) {
                std.debug.print("Audio: thread state - enabled={}->{}, playing={}->{}\n", .{last_enabled, enabled, last_playing, playing});
                last_enabled = enabled;
                last_playing = playing;
                // Reset debug flag on state change
                self.mutex.lock();
                self.debug_wrote_after_toggle = false;
                self.mutex.unlock();
            }

            // Check both enabled and playing states
            if (!enabled or !playing) {
                // Sleep when not playing to avoid busy-waiting
                // Don't generate samples when disabled - this ensures clean state when re-enabled
                std.Thread.sleep(10 * std.time.ns_per_ms);
                continue;
            }
            
            // Double-check state after sleep (in case it changed)
            const enabled_after_sleep = self.enabled.load(.acquire);
            const playing_after_sleep = self.playing.load(.acquire);
            if (!enabled_after_sleep or !playing_after_sleep) {
                if (enabled_after_sleep != enabled or playing_after_sleep != playing) {
                    std.debug.print("Audio: state changed during sleep - enabled={}->{}, playing={}->{}\n", .{enabled, enabled_after_sleep, playing, playing_after_sleep});
                }
                continue;
            }

            // If we're resuming playback after being stopped, prepare ALSA handle
            if (enabled_after_sleep and playing_after_sleep and !last_playing) {
                std.debug.print("Audio: Resuming playback, preparing ALSA handle\n", .{});
                self.mutex.lock();
                if (self.pcm_handle) |h| {
                    const prepare_result = c.snd_pcm_prepare(h);
                    if (prepare_result < 0) {
                        std.debug.print("Audio: Failed to prepare ALSA handle: {d}\n", .{prepare_result});
                    } else {
                        std.debug.print("Audio: ALSA handle prepared successfully\n", .{});
                    }
                }
                self.mutex.unlock();
            }

            // Debug: Show when audio is actually playing (only on state change to avoid spam)
            // std.debug.print("Audio: Generating and writing audio (enabled={}, playing={})\n", .{enabled_after_sleep, playing_after_sleep});

            // Generate audio samples
            self.mutex.lock();
            var sample_idx: usize = 0;
            while (sample_idx < buffer.len) : (sample_idx += 1) {
                buffer[sample_idx] = self.generateSample();
            }
            self.mutex.unlock();

            // Debug: Check if we generated non-zero samples
            var has_audio = false;
            for (buffer) |sample| {
                if (sample != 0) {
                    has_audio = true;
                    break;
                }
            }
            // std.debug.print("Audio: Generated buffer has audio: {}\n", .{has_audio});

            // Write to ALSA (blocking)
            var frames_written: c.snd_pcm_sframes_t = 0;
            var frames_to_write: c.snd_pcm_uframes_t = buffer.len;
            var ptr: [*]i16 = &buffer;

            while (frames_to_write > 0 and !self.should_stop.load(.acquire)) {
                // Check if music is still enabled before writing
                const enabled_before_write = self.enabled.load(.acquire);
                const playing_before_write = self.playing.load(.acquire);
                if (!enabled_before_write or !playing_before_write) {
                    // std.debug.print("Audio: write stopped - enabled={}, playing={}\n", .{enabled_before_write, playing_before_write});
                    break;
                }
                
                frames_written = c.snd_pcm_writei(handle, ptr, frames_to_write);

                if (frames_written < 0) {
                    // Check if we're shutting down - if so, break silently
                    if (self.should_stop.load(.acquire)) {
                        // Expected shutdown, break silently
                        break;
                    }
                    // Check if music was disabled during write
                    if (!self.enabled.load(.acquire) or !self.playing.load(.acquire)) {
                        break;
                    }
                    // EPIPE (-32) can happen during shutdown
                    if (frames_written == -32) {
                        // EPIPE - broken pipe, likely shutdown
                        break;
                    }
                    // For other errors, try recovery and retry
                    std.debug.print("Audio: ALSA write error: {d}, attempting recovery\n", .{frames_written});
                    const recover_result = c.snd_pcm_recover(handle, @intCast(frames_written), 1);
                    if (recover_result < 0) {
                        // Recovery failed, skip this buffer
                        std.debug.print("Audio: Recovery failed: {d}\n", .{recover_result});
                        break;
                    }
                    // Recovery succeeded, retry the write
                    continue;
                } else {
                    const written: usize = @intCast(frames_written);
                    frames_to_write -= written;
                    ptr += written;

                    // Debug: Show that we're writing audio (only first time after state change)
                    self.mutex.lock();
                    if (written > 0 and !self.debug_wrote_after_toggle) {
                        std.debug.print("Audio: Successfully resumed playback - wrote {d} frames to ALSA\n", .{written});
                        self.debug_wrote_after_toggle = true;
                    }
                    // Reset flag when buffer is complete
                    if (frames_to_write == 0) {
                        self.debug_wrote_after_toggle = false;
                    }
                    self.mutex.unlock();
                }
            }
        }

        // Cleanup
        {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (handle) |h| {
                // Drain and close - errors are expected if already closed
                _ = c.snd_pcm_drain(h);
                _ = c.snd_pcm_close(h);
            }
            self.pcm_handle = null;
        }
    }

    pub fn deinit(self: *AudioPlayer) void {
        // Signal the audio thread to stop
        self.should_stop.store(true, .release);

        // Stop playing and wait for the thread to finish
        self.playing.store(false, .release);
        self.enabled.store(false, .release);

        // Get a local copy of the thread handle before joining
        // This avoids potential issues with accessing self.audio_thread
        const thread_to_join = self.audio_thread;
        
        // Give the thread a moment to stop gracefully
        std.Thread.sleep(100 * std.time.ns_per_ms);

        // Safety check - audio_thread might be null if initialization failed
        if (thread_to_join) |thread| {
            thread.join();
        } else {
            std.debug.print("Audio: deinit called but audio_thread was null\n", .{});
        }

        // Ensure ALSA handle is closed (may already be closed by thread)
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.pcm_handle) |handle| {
            // Drain and close - errors are expected if already closed by thread
            _ = c.snd_pcm_drain(handle);
            _ = c.snd_pcm_close(handle);
            self.pcm_handle = null;
        }
    }

    pub fn play(self: *AudioPlayer) void {
        // Only play if music is enabled (respect user's toggle)
        const enabled = self.enabled.load(.acquire);
        if (!enabled) {
            // Don't spam - only print occasionally
            // std.debug.print("Audio: play() called but music is disabled, ignoring\n", .{});
            return;
        }
        const current = self.playing.load(.acquire);
        if (!current) {
            std.debug.print("Audio: play() - starting playback\n", .{});
            self.playing.store(true, .release);
        }
    }

    pub fn stop(self: *AudioPlayer) void {
        const current = self.playing.load(.acquire);
        if (current) {
            std.debug.print("Audio: stop() - stopping playback\n", .{});
            self.playing.store(false, .release);
        }
    }

    pub fn toggle(self: *AudioPlayer) void {
        const current = self.enabled.load(.acquire);
        const current_playing = self.playing.load(.acquire);
        const new_state = !current;
        std.debug.print("Audio: toggle() - enabled: {} -> {}, playing: {} -> {}\n", .{ current, new_state, current_playing, new_state });
        self.enabled.store(new_state, .release);
        self.playing.store(new_state, .release);
    }

    pub fn update(self: *AudioPlayer) void {
        // No longer needed - audio runs in separate thread
        _ = self;
    }

    fn generateSample(self: *AudioPlayer) i16 {
        // Safety check for note index
        if (self.note_index >= melody.len) {
            self.note_index = 0;
            self.note_sample_position = 0;
            self.sample_index = 0;
        }

        const current_note = melody[self.note_index];
        const note_samples: u32 = @intFromFloat(current_note.duration * @as(f32, @floatFromInt(samples_per_beat)));

        // Calculate envelope for smooth transitions
        const fade_samples: u32 = @min(note_samples / 10, 400);
        var envelope: f32 = 1.0;

        if (self.note_sample_position < fade_samples) {
            envelope = @as(f32, @floatFromInt(self.note_sample_position)) / @as(f32, @floatFromInt(fade_samples));
        } else if (self.note_sample_position > note_samples - fade_samples) {
            const remaining = if (self.note_sample_position >= note_samples) 0 else note_samples - self.note_sample_position;
            envelope = @as(f32, @floatFromInt(remaining)) / @as(f32, @floatFromInt(fade_samples));
        }

        // Generate sine wave
        var sample: f32 = 0.0;
        if (current_note.freq > 0) {
            const phase = @as(f32, @floatFromInt(self.sample_index)) * current_note.freq / @as(f32, @floatFromInt(SAMPLE_RATE));
            const two_pi = 2.0 * std.math.pi;
            sample = std.math.sin(phase * two_pi) * AMPLITUDE;
            sample *= envelope;
        }

        // Advance position
        self.sample_index += 1;
        self.note_sample_position += 1;

        if (self.note_sample_position >= note_samples) {
            self.note_sample_position = 0;
            self.note_index = (self.note_index + 1) % melody.len;
        }

        return @intFromFloat(sample);
    }

    pub fn setEnabled(self: *AudioPlayer, enabled: bool) void {
        const current = self.enabled.load(.acquire);
        if (current != enabled) {
            std.debug.print("Audio: setEnabled() - {} -> {}\n", .{current, enabled});
            self.enabled.store(enabled, .release);
            // Don't automatically set playing - let play()/stop() handle that
            // Only set playing to false if disabling, to stop immediately
            if (!enabled) {
                self.playing.store(false, .release);
            }
        }
    }

    pub fn isEnabled(self: *const AudioPlayer) bool {
        return self.enabled.load(.acquire);
    }
};
