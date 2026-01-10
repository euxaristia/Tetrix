const std = @import("std");
const c = @import("c.zig");

pub const SAMPLE_RATE: u32 = 44100;
const AMPLITUDE: f32 = 5500.0;
const TEMPO_BPM: f32 = 149.0;

// Note frequencies
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

// Korobeiniki melody (Tetris theme)
const melody = [_]Note{
    // First phrase
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 1.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 2.0 },

    // Second phrase
    .{ .freq = NOTE_FREQ.REST, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.F5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.A5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.G5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.F5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 2.0 },

    // Third phrase (repeat of first)
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.D5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.B4, .duration = 1.5 },
    .{ .freq = NOTE_FREQ.C5, .duration = 0.5 },
    .{ .freq = NOTE_FREQ.D5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.E5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.C5, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 1.0 },
    .{ .freq = NOTE_FREQ.A4, .duration = 2.0 },
};

pub const AudioPlayer = struct {
    enabled: bool = true,
    playing: bool = false,
    sample_index: u64 = 0,
    note_index: usize = 0,
    note_sample_position: u32 = 0,
    pcm_handle: ?*c.snd_pcm_t = null,

    const samples_per_beat: u32 = @intFromFloat(@as(f32, @floatFromInt(SAMPLE_RATE)) * 60.0 / TEMPO_BPM);

    pub fn init() AudioPlayer {
        var player = AudioPlayer{};
        player.initAlsa();
        return player;
    }

    fn initAlsa(self: *AudioPlayer) void {
        var handle: ?*c.snd_pcm_t = null;

        // Open PCM device for playback in non-blocking mode
        if (c.snd_pcm_open(&handle, "default", c.SND_PCM_STREAM_PLAYBACK, c.SND_PCM_NONBLOCK) < 0) {
            std.debug.print("Failed to open ALSA device\n", .{});
            return;
        }

        // Set parameters
        var params: ?*c.snd_pcm_hw_params_t = null;
        _ = c.snd_pcm_hw_params_malloc(&params);
        _ = c.snd_pcm_hw_params_any(handle, params);
        _ = c.snd_pcm_hw_params_set_access(handle, params, c.SND_PCM_ACCESS_RW_INTERLEAVED);
        _ = c.snd_pcm_hw_params_set_format(handle, params, c.SND_PCM_FORMAT_S16_LE);
        _ = c.snd_pcm_hw_params_set_channels(handle, params, 1);

        var rate: c_uint = SAMPLE_RATE;
        _ = c.snd_pcm_hw_params_set_rate_near(handle, params, &rate, null);

        // Set smaller buffer for lower latency
        var buffer_size: c.snd_pcm_uframes_t = 4096;
        _ = c.snd_pcm_hw_params_set_buffer_size_near(handle, params, &buffer_size);

        var period_size: c.snd_pcm_uframes_t = 1024;
        _ = c.snd_pcm_hw_params_set_period_size_near(handle, params, &period_size, null);

        _ = c.snd_pcm_hw_params(handle, params);
        _ = c.snd_pcm_hw_params_free(params);

        _ = c.snd_pcm_prepare(handle);

        self.pcm_handle = handle;
    }

    pub fn deinit(self: *AudioPlayer) void {
        if (self.pcm_handle) |handle| {
            _ = c.snd_pcm_drain(handle);
            _ = c.snd_pcm_close(handle);
            self.pcm_handle = null;
        }
    }

    pub fn play(self: *AudioPlayer) void {
        self.playing = true;
    }

    pub fn stop(self: *AudioPlayer) void {
        self.playing = false;
    }

    pub fn toggle(self: *AudioPlayer) void {
        self.enabled = !self.enabled;
    }

    pub fn update(self: *AudioPlayer) void {
        if (!self.enabled or !self.playing or self.pcm_handle == null) return;

        const handle = self.pcm_handle.?;

        // Generate larger audio buffer to prevent underruns
        var buffer: [2048]i16 = undefined;

        for (&buffer) |*sample| {
            sample.* = self.generateSample();
        }

        // Write to ALSA (non-blocking, silent recovery)
        const frames = c.snd_pcm_writei(handle, &buffer, buffer.len);
        if (frames < 0) {
            // Silently recover from any error (1 = silent)
            _ = c.snd_pcm_recover(handle, @intCast(frames), 1);
        }
    }

    fn generateSample(self: *AudioPlayer) i16 {
        const current_note = melody[self.note_index];
        const note_samples: u32 = @intFromFloat(current_note.duration * @as(f32, @floatFromInt(samples_per_beat)));

        // Calculate envelope for smooth transitions
        const fade_samples: u32 = @min(note_samples / 10, 800);
        var envelope: f32 = 1.0;

        if (self.note_sample_position < fade_samples) {
            envelope = @as(f32, @floatFromInt(self.note_sample_position)) / @as(f32, @floatFromInt(fade_samples));
        } else if (self.note_sample_position > note_samples - fade_samples) {
            envelope = @as(f32, @floatFromInt(note_samples - self.note_sample_position)) / @as(f32, @floatFromInt(fade_samples));
        }

        // Generate sine wave
        var sample: f32 = 0.0;
        if (current_note.freq > 0) {
            const phase = @as(f32, @floatFromInt(self.sample_index)) * current_note.freq * 2.0 * std.math.pi / @as(f32, @floatFromInt(SAMPLE_RATE));
            sample = @sin(phase) * AMPLITUDE * envelope;
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
        self.enabled = enabled;
    }

    pub fn isEnabled(self: *const AudioPlayer) bool {
        return self.enabled;
    }
};
