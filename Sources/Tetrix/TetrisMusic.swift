import Foundation
import CSDL3

// MARK: - Swift-Native Audio Types (replaces SDL audio C types)

/// Swift-native audio specification (replaces SDL_AudioSpec)
struct AudioSpec {
    var frequency: Int32
    var format: UInt32
    var channels: UInt8
    
    init(frequency: Int32, format: UInt32, channels: UInt8) {
        self.frequency = frequency
        self.format = format
        self.channels = channels
    }
    
    /// Convert to SDL_AudioSpec for C interop
    func toSDL() -> SDL_AudioSpec {
        var sdlSpec = SDL_AudioSpec()
        sdlSpec.freq = frequency
        sdlSpec.format = SDL_AudioFormat(rawValue: format)
        sdlSpec.channels = Int32(channels)
        return sdlSpec
    }
}

// MARK: - SDL Audio Wrapper (replaces direct SDL audio calls)

/// Swift-native audio stream wrapper (replaces SDL_AudioStream)
class AudioStream {
    private var sdlStream: OpaquePointer?
    
    init?(device: UInt32, spec: AudioSpec, allowedChanges: UInt32 = 0, callback: UnsafeMutableRawPointer? = nil) {
        var sdlSpec = spec.toSDL()
        // SDL_OpenAudioDeviceStream signature: (devid, spec, callback, userdata)
        // callback is SDL_AudioStreamCallback?, userdata is UnsafeMutableRawPointer?
        // We pass callback as nil and userdata as nil
        let callbackPtr: SDL_AudioStreamCallback? = nil
        let userdata: UnsafeMutableRawPointer? = nil
        sdlStream = SDL_OpenAudioDeviceStream(device, &sdlSpec, callbackPtr, userdata)
        if sdlStream == nil {
            return nil
        }
    }
    
    func resume() {
        if let stream = sdlStream {
            SDL_ResumeAudioStreamDevice(stream)
        }
    }
    
    func pause() {
        if let stream = sdlStream {
            SDL_PauseAudioStreamDevice(stream)
        }
    }
    
    func getQueued() -> Int32 {
        guard let stream = sdlStream else { return 0 }
        return SDL_GetAudioStreamQueued(stream)
    }
    
    func putData(_ data: UnsafeRawPointer, _ len: Int32) -> Bool {
        guard let stream = sdlStream else { return false }
        return SDL_PutAudioStreamData(stream, data, len)
    }
    
    deinit {
        if let stream = sdlStream {
            SDL_DestroyAudioStream(stream)
        }
    }
}

/// SDL audio constants (replaces SDL_* constants)
enum AudioFormat {
    static var s16: UInt32 {
        return UInt32(SDL_AUDIO_S16.rawValue)
    }
}

enum AudioDevice {
    static let defaultPlayback = SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK
}

class TetrisMusic {
    // Musical note frequencies (Hz) - just the notes we need for Tetris theme
    // Based on A4 = 440Hz standard tuning
    private let noteFreqs: [String: Double] = [
        "E5": 659.25,  // E5
        "B4": 493.88,  // B4
        "C5": 523.25,  // C5
        "D5": 587.33,  // D5
        "E4": 329.63,  // E4 (lower octave)
        "C4": 261.63,  // C4 (lower octave)
        "A4": 440.00,  // A4
        "G4": 392.00,  // G4
        "F4": 349.23,  // F4
        "F5": 698.46,  // F5
        "D4": 293.66,  // D4
        "G5": 783.99,  // G5
        "A5": 880.00,  // A5
        "E3": 164.81,  // E3 (even lower)
        "C3": 130.81,  // C3 (even lower)
        "G3": 196.00,  // G3
        "A3": 220.00,  // A3
        "B3": 246.94,  // B3
        "F3": 174.61,  // F3
        "E6": 1318.51  // E6 (higher octave)
    ]
    
    private var audioStream: AudioStream? = nil
    private var sampleRate: Int = 44100
    private var isPlaying = false
    private var samplesGenerated = 0
    
    // Tetris theme melody - Korobeiniki (classic Tetris Type A theme, complete loop)
    // Format: (note, duration in beats) - extended to full Game Boy version
    private let melody: [(note: String, duration: Double)] = [
        // First phrase (2/4 time, eighth notes and quarter notes)
        ("E5", 0.5), ("B4", 0.5), ("C5", 0.5), ("D5", 0.5),
        ("C5", 0.5), ("B4", 0.5), ("A4", 1.5),
        // Second phrase
        ("A4", 0.5), ("C5", 0.5), ("E5", 0.5), ("D5", 0.5),
        ("C5", 0.5), ("B4", 0.5), ("B4", 1.5),
        // Third phrase
        ("C5", 0.5), ("D5", 0.5), ("E5", 1.0),
        ("C5", 1.0), ("A4", 1.0), ("A4", 1.0),
        // Fourth phrase
        ("D5", 1.0), ("F5", 0.5), ("A5", 0.5), ("G5", 0.5), ("F5", 0.5),
        ("E5", 1.0), ("C5", 0.5), ("E5", 0.5), ("D5", 0.5), ("C5", 0.5),
        ("B4", 1.0), ("B4", 0.5), ("C5", 0.5),
        ("D5", 1.0), ("E5", 1.0), ("C5", 1.0), ("A4", 1.0), ("A4", 1.0),
        // Extended section - middle part of the full melody
        ("E5", 0.5), ("B4", 0.5), ("C5", 0.5), ("D5", 0.5),
        ("C5", 0.5), ("B4", 0.5), ("A4", 1.5),
        ("A4", 0.5), ("C5", 0.5), ("E5", 0.5), ("D5", 0.5),
        ("C5", 0.5), ("B4", 0.5), ("B4", 1.5),
        ("C5", 0.5), ("D5", 0.5), ("E5", 1.0),
        ("C5", 1.0), ("A4", 1.0), ("A4", 1.0),
        // Final phrase leading back to start
        ("D5", 1.0), ("F5", 0.5), ("A5", 0.5), ("G5", 0.5), ("F5", 0.5),
        ("E5", 1.0), ("C5", 0.5), ("E5", 0.5), ("D5", 0.5), ("C5", 0.5),
        ("B4", 1.0), ("B4", 0.5), ("C5", 0.5),
        ("D5", 1.0), ("E5", 1.0), ("C5", 1.0), ("A4", 1.0),
        // Extended ending for smoother loop - resolves more naturally
        ("G4", 2.0), ("A4", 1.0), ("B4", 1.0)
    ]
    
    private let tempo: Double = 149.0 // Beats per minute (matches Game Boy Tetris Type A tempo more accurately)
    private var currentNoteIndex = 0
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        let spec = AudioSpec(
            frequency: Int32(sampleRate),
            format: AudioFormat.s16,  // SDL3: 16-bit signed samples (UInt32)
            channels: 1  // Mono audio
        )
        
        // SDL3: Use Swift-native audio stream wrapper
        // Pass nil for callback - we'll queue data manually
        audioStream = AudioStream(device: AudioDevice.defaultPlayback, spec: spec)
        
        if audioStream == nil {
            let errorString = String.sdlError() ?? "Unknown error"
            print("Warning: Failed to open audio device: \(errorString)")
            return
        }
        
        // SDL3: Device starts paused, resume to start playback
        audioStream?.resume()
    }
    
    func start() {
        guard audioStream != nil else { return }
        isPlaying = true
        currentNoteIndex = 0
        samplesGenerated = 0
        // Pre-fill some audio
        for _ in 0..<5 {
            generateAndQueueAudio()
        }
    }
    
    func stop() {
        isPlaying = false
    }
    
    func update() {
        guard isPlaying, let stream = audioStream else { return }
        
        // Keep the audio queue filled (generate ahead)
        // SDL3: Use Swift-native audio stream wrapper
        let queuedSize = stream.getQueued()
        let bytesPerSecond = sampleRate * 2 // sampleRate * 2 bytes (16-bit) * 1 channel
        let targetQueueSize = bytesPerSecond / 4 // 250ms buffer
        
        if queuedSize < targetQueueSize {
            generateAndQueueAudio()
        }
    }
    
    private func generateAndQueueAudio() {
        // Generate one note at a time
        guard currentNoteIndex < melody.count else { return }
        let noteData = melody[currentNoteIndex]
        guard let freq = noteFreqs[noteData.note] else {
            // Skip to next note if frequency not found
            currentNoteIndex = (currentNoteIndex + 1) % melody.count
            return
        }
        
        let duration = noteData.duration * (60.0 / tempo)
        let numSamples = Int(Double(sampleRate) * duration)
        var samples = [Int16](repeating: 0, count: numSamples)
        
        let amplitude: Double = 5500.0 // 16-bit audio, quiet volume (~17% of range) for background music
        let twoPi = 2.0 * Double.pi
        
        for i in 0..<numSamples {
            let time = Double(samplesGenerated + i) / Double(sampleRate)
            // Generate sine wave with envelope (fade in/out to avoid clicks)
            let envelope: Double
            let fadeSamples = min(numSamples / 10, 800) // Fade over first/last portion
            if i < fadeSamples {
                envelope = Double(i) / Double(fadeSamples)
            } else if i >= numSamples - fadeSamples {
                envelope = Double(numSamples - i) / Double(fadeSamples)
            } else {
                envelope = 1.0
            }
            
            let sample = sin(twoPi * freq * time) * amplitude * envelope
            samples[i] = Int16(max(-32768, min(32767, sample)))
        }
        
        samplesGenerated += numSamples
        
        // SDL3: Use Swift-native audio stream wrapper
        guard let stream = audioStream else { return }
        let _ = samples.withUnsafeBufferPointer { buffer in
            let bytesToWrite = samples.count * 2  // 2 bytes per Int16 sample
            _ = stream.putData(buffer.baseAddress!, Int32(bytesToWrite))
        }
        
        // Move to next note
        currentNoteIndex = (currentNoteIndex + 1) % melody.count
    }
    
    deinit {
        // AudioStream deinit will clean up SDL stream automatically
        audioStream = nil
    }
}
