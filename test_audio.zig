const std = @import("std");
const c = @import("zig-version/src/c.zig");

pub fn main() !void {
    std.debug.print("Testing simple audio playback...\n", .{});

    // Try to open the default ALSA device
    var handle: ?*c.snd_pcm_t = null;
    const open_result = c.snd_pcm_open(&handle, "default", c.SND_PCM_STREAM_PLAYBACK, 0);

    if (open_result < 0) {
        std.debug.print("Failed to open ALSA device: {d}\n", .{open_result});
        return;
    }

    std.debug.print("Successfully opened ALSA device\n", .{});
    defer {
        if (handle) |h| {
            _ = c.snd_pcm_drain(h);
            _ = c.snd_pcm_close(h);
        }
    }

    // Set up parameters
    var params: ?*c.snd_pcm_hw_params_t = null;
    _ = c.snd_pcm_hw_params_malloc(&params);
    defer _ = c.snd_pcm_hw_params_free(params);

    _ = c.snd_pcm_hw_params_any(handle, params);
    _ = c.snd_pcm_hw_params_set_access(handle, params, c.SND_PCM_ACCESS_RW_INTERLEAVED);
    _ = c.snd_pcm_hw_params_set_format(handle, params, c.SND_PCM_FORMAT_S16_LE);
    _ = c.snd_pcm_hw_params_set_channels(handle, params, 1);

    var rate: c_uint = 48000; // Match the working aplay format
    _ = c.snd_pcm_hw_params_set_rate_near(handle, params, &rate, null);

    // Set buffer parameters
    var buffer_size: c.snd_pcm_uframes_t = 4096;
    _ = c.snd_pcm_hw_params_set_buffer_size_near(handle, params, &buffer_size);

    var period_size: c.snd_pcm_uframes_t = 1024;
    _ = c.snd_pcm_hw_params_set_period_size_near(handle, params, &period_size, null);

    if (c.snd_pcm_hw_params(handle, params) < 0) {
        std.debug.print("Failed to set ALSA parameters\n", .{});
        return;
    }

    if (c.snd_pcm_prepare(handle) < 0) {
        std.debug.print("Failed to prepare ALSA\n", .{});
        return;
    }

    std.debug.print("Starting simple tone playback...\n", .{});

    // Generate a simple 440Hz sine wave for 1 second
    const sample_rate: u32 = 48000;
    const frequency: f32 = 440.0; // A4 note
    const duration: f32 = 1.0; // 1 second
    const num_samples: usize = @intFromFloat(@as(f32, @floatFromInt(sample_rate)) * duration);

    var buffer: [1024]i16 = undefined;
    var sample_index: usize = 0;

    // Play the tone
    while (sample_index < num_samples) {
        // Generate samples for this buffer
        var buf_idx: usize = 0;
        while (buf_idx < buffer.len and sample_index < num_samples) : (buf_idx += 1) {
            const t = @as(f32, @floatFromInt(sample_index)) / @as(f32, @floatFromInt(sample_rate));
            const value = std.math.sin(t * frequency * 2.0 * std.math.pi) * 16000.0;
            buffer[buf_idx] = @intFromFloat(value);
            sample_index += 1;
        }

        // Write to ALSA
        var frames_written: c.snd_pcm_sframes_t = 0;
        var frames_to_write: c.snd_pcm_uframes_t = @intCast(buf_idx);
        var ptr: [*]i16 = &buffer;

        while (frames_to_write > 0) {
            frames_written = c.snd_pcm_writei(handle, ptr, frames_to_write);

            if (frames_written < 0) {
                std.debug.print("ALSA write error: {d}\n", .{frames_written});
                _ = c.snd_pcm_recover(handle, @intCast(frames_written), 1);
                break;
            } else {
                const written: usize = @intCast(frames_written);
                frames_to_write -= written;
                ptr += written;
            }
        }

        std.debug.print("Wrote {d} samples\n", .{buf_idx});
    }

    std.debug.print("Finished playing simple tone\n", .{});
}
