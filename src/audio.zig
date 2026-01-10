const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig");

pub const SAMPLE_RATE: u32 = 44100;

// Platform-specific sleep function
fn sleepMs(ms: u64) void {
    if (builtin.target.os.tag == .windows) {
        // Windows: Use Sleep from kernel32.dll
        const kernel32 = std.os.windows.kernel32;
        kernel32.Sleep(@intCast(ms));
    } else {
        // Unix: Use nanosleep
        const delay_ns = ms * std.time.ns_per_ms;
        std.posix.nanosleep(0, delay_ns);
    }
}
// Consistent amplitude across platforms for uniform volume level
// This value (10000.0) provides good volume representation on both Windows and Linux
const AMPLITUDE: f32 = 10000.0;
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
    pcm_handle: ?*c.snd_pcm_t = null, // ALSA handle (Linux)
    waveout_handle: ?c.HWAVEOUT = null, // waveOut handle (Windows)
    waveout_headers: [4]c.WAVEHDR = undefined, // waveOut buffers (Windows)
    waveout_buffer_data: [4][4096]u8 = undefined, // Audio buffer data (Windows)
    waveout_current_buffer: usize = 0, // Current buffer index (Windows)
    debug_wrote_after_toggle: bool = false,
    fade_volume: f32 = 1.0, // Fade volume multiplier (0.0 to 1.0) for smooth mute/unmute
    fade_samples_remaining: u32 = 0, // Samples remaining in fade transition

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

        // Platform-specific audio initialization
        if (builtin.target.os.tag == .linux) {
            self.initAlsa();
        } else if (builtin.target.os.tag == .windows) {
            self.initWaveOut();
        } else {
            std.debug.print("Audio: Not supported on this platform\n", .{});
            return;
        }
    }

    fn initAlsa(self: *AudioPlayer) void {

        // Initialize ALSA in blocking mode within the audio thread
        var handle: ?*c.snd_pcm_t = null;

        // Try multiple ALSA devices to find a working one
        // Prioritize "default" first for PipeWire compatibility (routes to default PipeWire device)
        std.debug.print("Audio: Trying to open ALSA devices...\n", .{});
        const devices = [_][*:0]const u8{
            "default", // PipeWire default device (should route to user's default audio device)
            "plughw:1,3", // Plug version for NVIDIA HDMI 0 - handles format conversion
            "plughw:1,7", // Plug version for NVIDIA HDMI 1
            "plughw:0,0", // Plug version for HyperX Wireless
            "plughw:2,0", // Plug version for Intel PCH Analog
            "sysdefault:CARD=NVidia", // System default for NVIDIA card
            "front:CARD=NVidia,DEV=3", // Front device for NVIDIA HDMI 0
            "hw:1,3", // NVIDIA HDMI 0 (DELL G2725D) - from aplay -l
            "hw:1,7", // NVIDIA HDMI 1
            "hw:0,0", // HyperX Wireless
            "hw:2,0", // Intel PCH Analog
        };

        var device_index: usize = 0;
        while (device_index < devices.len) : (device_index += 1) {
            const open_result = c.snd_pcm_open(&handle, devices[device_index], c.SND_PCM_STREAM_PLAYBACK, 0);
            if (open_result == 0) {
                // Successfully opened a device
                std.debug.print("Audio: Successfully opened device: {s}\n", .{devices[device_index]});
                break;
            } else {
                std.debug.print("Audio: Failed to open device {s}: {d}\n", .{ devices[device_index], open_result });
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

        // Track last state for debug output - initialize to current state
        const initial_enabled = self.enabled.load(.acquire);
        const initial_playing = self.playing.load(.acquire);
        var last_enabled: bool = initial_enabled;
        var last_playing: bool = initial_playing;
        
        // Initialize fade volume based on initial state
        self.mutex.lock();
        self.fade_volume = if (initial_enabled and initial_playing) 1.0 else 0.0;
        self.mutex.unlock();
        
        const FADE_DURATION_MS: u32 = 200; // 200ms fade for smoother transitions (increased to reduce popping)
        const FADE_DURATION_SAMPLES: u32 = (FADE_DURATION_MS * SAMPLE_RATE) / 1000; // ~8820 samples at 44.1kHz

        while (!self.should_stop.load(.acquire)) {
            const enabled = self.enabled.load(.acquire);
            const playing = self.playing.load(.acquire);

            // Handle fade transitions when muting/unmuting
            if (enabled != last_enabled or playing != last_playing) {
                std.debug.print("Audio: thread state - enabled={}->{}, playing={}->{}\n", .{ last_enabled, enabled, last_playing, playing });

                self.mutex.lock();
                if ((enabled and playing) and (!last_enabled or !last_playing)) {
                    // Unmuting: start fade in and prepare ALSA for clean start
                    self.fade_samples_remaining = FADE_DURATION_SAMPLES;
                    self.fade_volume = 0.0;
                    // Prepare ALSA handle for clean start
                    if (self.pcm_handle) |h| {
                        _ = c.snd_pcm_prepare(h);
                    }
                } else if ((!enabled or !playing) and (last_enabled and last_playing)) {
                    // Muting: start fade out (don't drain immediately - let fade complete)
                    self.fade_samples_remaining = FADE_DURATION_SAMPLES;
                    self.fade_volume = 1.0;
                }
                self.debug_wrote_after_toggle = false;
                self.mutex.unlock();

                last_enabled = enabled;
                last_playing = playing;
            }

            // Check both enabled and playing states
            if (!enabled or !playing) {
                // Still generate silence during fade-out to avoid pops
                self.mutex.lock();
                const fade_active = self.fade_samples_remaining > 0;
                self.mutex.unlock();
                if (!fade_active) {
                    // Sleep when not playing to avoid busy-waiting
                    sleepMs(10);
                    continue;
                }
            }

            // Double-check state after sleep (in case it changed)
            // But continue generating during fade-out to complete the fade smoothly
            const enabled_after_sleep = self.enabled.load(.acquire);
            const playing_after_sleep = self.playing.load(.acquire);
            self.mutex.lock();
            const fade_active = self.fade_samples_remaining > 0;
            self.mutex.unlock();
            if ((!enabled_after_sleep or !playing_after_sleep) and !fade_active) {
                if (enabled_after_sleep != enabled or playing_after_sleep != playing) {
                    std.debug.print("Audio: state changed during sleep - enabled={}->{}, playing={}->{}\n", .{ enabled, enabled_after_sleep, playing, playing_after_sleep });
                }
                continue;
            }

            // Check if we're resuming playback (before updating last_playing)
            const is_resuming = (enabled_after_sleep and playing_after_sleep) and (!last_enabled or !last_playing);

            // If we're resuming playback after being stopped, prepare ALSA handle
            if (is_resuming) {
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

            // Generate audio samples with per-sample fade (using cosine curve for smoother transition)
            self.mutex.lock();
            var sample_idx: usize = 0;
            while (sample_idx < buffer.len) : (sample_idx += 1) {
                var sample = self.generateSample();

                // Update fade per sample with cosine curve for smoother transition
                if (self.fade_samples_remaining > 0) {
                    const fade_progress = 1.0 - (@as(f32, @floatFromInt(self.fade_samples_remaining)) / @as(f32, @floatFromInt(FADE_DURATION_SAMPLES)));
                    // Use cosine curve for smoother fade (0 to pi/2)
                    const cosine_fade = 0.5 * (1.0 - std.math.cos(fade_progress * std.math.pi));
                    // Check current state to determine fade direction
                    const currently_enabled = self.enabled.load(.acquire);
                    const currently_playing = self.playing.load(.acquire);
                    if (currently_enabled and currently_playing) {
                        // Fade in: cosine from 0 to 1
                        self.fade_volume = cosine_fade;
                    } else {
                        // Fade out: cosine from 1 to 0
                        self.fade_volume = 1.0 - cosine_fade;
                    }
                    self.fade_samples_remaining -= 1;
                } else {
                    // No fade active, set to final state
                    const currently_enabled = self.enabled.load(.acquire);
                    const currently_playing = self.playing.load(.acquire);
                    self.fade_volume = if (currently_enabled and currently_playing) 1.0 else 0.0;
                }

                // Apply fade volume to prevent pops when muting/unmuting
                // Ensure we write silence (0) when volume is 0 to avoid any residual audio
                if (self.fade_volume <= 0.0) {
                    buffer[sample_idx] = 0;
                } else {
                    sample = @intFromFloat(@as(f32, @floatFromInt(sample)) * self.fade_volume);
                    buffer[sample_idx] = sample;
                }
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
                // But continue writing during fade-out to avoid pops
                self.mutex.lock();
                const fade_active_write = self.fade_samples_remaining > 0;
                self.mutex.unlock();
                const enabled_before_write = self.enabled.load(.acquire);
                const playing_before_write = self.playing.load(.acquire);
                if ((!enabled_before_write or !playing_before_write) and !fade_active_write) {
                    // Only stop if not fading (fade will handle the transition)
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
                    // Note: flag is reset when state changes, so this only logs once per resume
                    if (written > 0) {
                        self.mutex.lock();
                        defer self.mutex.unlock();
                        if (!self.debug_wrote_after_toggle) {
                            std.debug.print("Audio: Successfully resumed playback - wrote {d} frames to ALSA\n", .{written});
                            self.debug_wrote_after_toggle = true;
                        }
                    }
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

    fn initWaveOut(self: *AudioPlayer) void {
        std.debug.print("Audio: Initializing waveOut...\n", .{});

        // Set up WAVEFORMATEX for 16-bit PCM, mono, 44100 Hz
        var format = c.WAVEFORMATEX{
            .wFormatTag = c.WAVE_FORMAT_PCM,
            .nChannels = 1,
            .nSamplesPerSec = SAMPLE_RATE,
            .nAvgBytesPerSec = SAMPLE_RATE * 2, // 16-bit = 2 bytes per sample
            .nBlockAlign = 2, // 1 channel * 2 bytes
            .wBitsPerSample = 16,
            .cbSize = 0,
        };

        // Open waveOut device
        var waveOut: c.HWAVEOUT = undefined;
        const result = c.waveOutOpen(
            &waveOut,
            c.WAVE_MAPPER,
            &format,
            0, // No callback
            0, // No instance data
            c.CALLBACK_NULL,
        );
        if (result != 0) {
            std.debug.print("Audio: Failed to open waveOut device (error code: {d})\n", .{result});
            std.debug.print("Audio: If running under Wine, ensure PulseAudio/ALSA is configured:\n", .{});
            std.debug.print("Audio:   export PULSE_RUNTIME_PATH=/run/user/$UID/pulse\n", .{});
            std.debug.print("Audio:   winecfg -> Audio -> Enable audio driver\n", .{});
            return;
        }

        std.debug.print("Audio: waveOut device opened successfully\n", .{});

        // Initialize buffers
        {
            self.mutex.lock();
            defer self.mutex.unlock();
            self.waveout_handle = waveOut;
            self.waveout_current_buffer = 0;

            // Initialize all WAVEHDR structures
            for (&self.waveout_headers, 0..) |*header, i| {
                header.* = std.mem.zeroes(c.WAVEHDR);
                header.lpData = &self.waveout_buffer_data[i];
                header.dwBufferLength = @intCast(self.waveout_buffer_data[i].len);
                header.dwFlags = 0;
                header.dwLoops = 0;

                // Prepare header
                const prep_result = c.waveOutPrepareHeader(waveOut, header, @sizeOf(c.WAVEHDR));
                if (prep_result != 0) {
                    std.debug.print("Audio: Failed to prepare waveOut header {d}: {d}\n", .{ i, prep_result });
                    _ = c.waveOutClose(waveOut);
                    self.waveout_handle = null;
                    return;
                }
            }
        }

        std.debug.print("Audio: waveOut initialized successfully\n", .{});

        // Audio generation loop
        // Track last state - initialize to current state
        const initial_enabled = self.enabled.load(.acquire);
        const initial_playing = self.playing.load(.acquire);
        var last_enabled: bool = initial_enabled;
        var last_playing: bool = initial_playing;
        
        // Initialize fade volume based on initial state
        self.mutex.lock();
        self.fade_volume = if (initial_enabled and initial_playing) 1.0 else 0.0;
        self.mutex.unlock();
        
        const FADE_DURATION_MS: u32 = 200; // 200ms fade for smoother transitions (increased to reduce popping)
        const FADE_DURATION_SAMPLES: u32 = (FADE_DURATION_MS * SAMPLE_RATE) / 1000; // ~8820 samples at 44.1kHz

        while (!self.should_stop.load(.acquire)) {
            const enabled = self.enabled.load(.acquire);
            const playing = self.playing.load(.acquire);

            // Handle fade transitions when muting/unmuting
            if (enabled != last_enabled or playing != last_playing) {
                std.debug.print("Audio: thread state - enabled={}->{}, playing={}->{}\n", .{ last_enabled, enabled, last_playing, playing });

                self.mutex.lock();
                if ((enabled and playing) and (!last_enabled or !last_playing)) {
                    // Unmuting: start fade in and reset waveOut for clean start
                    self.fade_samples_remaining = FADE_DURATION_SAMPLES;
                    self.fade_volume = 0.0;
                    // Reset waveOut to clear any stale buffers
                    if (self.waveout_handle) |h| {
                        _ = c.waveOutReset(h);
                    }
                } else if ((!enabled or !playing) and (last_enabled and last_playing)) {
                    // Muting: start fade out (don't reset immediately - let fade complete)
                    self.fade_samples_remaining = FADE_DURATION_SAMPLES;
                    self.fade_volume = 1.0;
                }
                self.debug_wrote_after_toggle = false;
                self.mutex.unlock();

                last_enabled = enabled;
                last_playing = playing;
            }

            if (!enabled or !playing) {
                // Still generate silence during fade-out to avoid pops
                self.mutex.lock();
                const fade_active = self.fade_samples_remaining > 0;
                self.mutex.unlock();
                if (!fade_active) {
                    sleepMs(10);
                    continue;
                }
            }

            const enabled_after_sleep = self.enabled.load(.acquire);
            const playing_after_sleep = self.playing.load(.acquire);
            if (!enabled_after_sleep or !playing_after_sleep) {
                continue;
            }

            // Get current buffer
            self.mutex.lock();
            const handle = self.waveout_handle;
            const current_idx = self.waveout_current_buffer;
            var header = &self.waveout_headers[current_idx];
            self.mutex.unlock();

            if (handle == null) {
                break;
            }

            // Check if buffer is done (ready for new data)
            // Buffer is ready if: it's done playing (WHDR_DONE), or it's not in queue (first use or done)
            const is_done = (header.dwFlags & c.WHDR_DONE) != 0;
            const is_in_queue = (header.dwFlags & c.WHDR_INQUEUE) != 0;
            const is_ready = is_done or !is_in_queue;

            if (is_ready) {
                // Generate audio samples into buffer with per-sample fade
                self.mutex.lock();
                var sample_idx: usize = 0;
                const buffer_len = self.waveout_buffer_data[current_idx].len / 2; // 16-bit samples
                var samples: [4096]i16 = undefined;
                while (sample_idx < buffer_len and sample_idx < samples.len) : (sample_idx += 1) {
                    var sample = self.generateSample();

                    // Update fade per sample with cosine curve for smoother transition
                    if (self.fade_samples_remaining > 0) {
                        const fade_progress = 1.0 - (@as(f32, @floatFromInt(self.fade_samples_remaining)) / @as(f32, @floatFromInt(FADE_DURATION_SAMPLES)));
                        // Use cosine curve for smoother fade (0 to pi/2)
                        const cosine_fade = 0.5 * (1.0 - std.math.cos(fade_progress * std.math.pi));
                        if (enabled and playing) {
                            // Fade in: cosine from 0 to 1
                            self.fade_volume = cosine_fade;
                        } else {
                            // Fade out: cosine from 1 to 0
                            self.fade_volume = 1.0 - cosine_fade;
                        }
                        self.fade_samples_remaining -= 1;
                    } else {
                        // No fade active, set to final state
                        self.fade_volume = if (enabled and playing) 1.0 else 0.0;
                    }

                    // Apply fade volume to prevent pops
                    // Ensure we write silence (0) when volume is 0 to avoid any residual audio
                    if (self.fade_volume <= 0.0) {
                        samples[sample_idx] = 0;
                    } else {
                        sample = @intFromFloat(@as(f32, @floatFromInt(sample)) * self.fade_volume);
                        samples[sample_idx] = sample;
                    }
                }
                self.mutex.unlock();

                // Copy samples to buffer (16-bit = 2 bytes per sample)
                @memcpy(
                    self.waveout_buffer_data[current_idx][0 .. sample_idx * 2],
                    std.mem.sliceAsBytes(samples[0..sample_idx]),
                );

                // Set buffer length and ensure header is prepared
                header.dwBufferLength = @intCast(sample_idx * 2);
                header.dwFlags = c.WHDR_PREPARED; // Mark as prepared before writing

                // Write buffer to waveOut
                const write_result = c.waveOutWrite(handle.?, header, @sizeOf(c.WAVEHDR));
                if (write_result != 0) {
                    std.debug.print("Audio: Failed to write waveOut buffer (error {d}), header flags: 0x{x}\n", .{ write_result, header.dwFlags });
                    sleepMs(10);
                    continue;
                }

                // After successful write, the buffer should be in queue
                // Check flags after a short delay to ensure it was queued
                sleepMs(1);

                // Move to next buffer
                self.mutex.lock();
                self.waveout_current_buffer = (current_idx + 1) % 4;
                if (!self.debug_wrote_after_toggle) {
                    std.debug.print("Audio: Successfully wrote {d} samples to waveOut\n", .{sample_idx});
                    self.debug_wrote_after_toggle = true;
                }
                self.mutex.unlock();
            } else {
                // Buffer still playing, wait a bit
                sleepMs(5);
            }
        }

        // Cleanup
        {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.waveout_handle) |h| {
                // Reset and unprepare all headers
                _ = c.waveOutReset(h);
                for (&self.waveout_headers) |*header| {
                    _ = c.waveOutUnprepareHeader(h, header, @sizeOf(c.WAVEHDR));
                }
                _ = c.waveOutClose(h);
            }
            self.waveout_handle = null;
        }

        std.debug.print("Audio: waveOut thread exiting\n", .{});
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
        sleepMs(100);

        // Safety check - audio_thread might be null if initialization failed
        if (thread_to_join) |thread| {
            thread.join();
        } else {
            std.debug.print("Audio: deinit called but audio_thread was null\n", .{});
        }

        // Ensure audio handles are closed (may already be closed by thread)
        self.mutex.lock();
        defer self.mutex.unlock();

        // Cleanup ALSA (Linux)
        if (self.pcm_handle) |handle| {
            // Drain and close - errors are expected if already closed by thread
            _ = c.snd_pcm_drain(handle);
            _ = c.snd_pcm_close(handle);
            self.pcm_handle = null;
        }

        // Cleanup waveOut (Windows)
        if (self.waveout_handle) |handle| {
            _ = c.waveOutReset(handle);
            for (&self.waveout_headers) |*header| {
                _ = c.waveOutUnprepareHeader(handle, header, @sizeOf(c.WAVEHDR));
            }
            _ = c.waveOutClose(handle);
            self.waveout_handle = null;
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
            std.debug.print("Audio: setEnabled() - {} -> {}\n", .{ current, enabled });
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
