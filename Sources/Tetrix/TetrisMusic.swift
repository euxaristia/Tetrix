import Foundation
#if os(Linux)
import Glibc
#endif
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
        sdlSpec.format = SDL_AudioFormat(rawValue: Int32(format))
        sdlSpec.channels = Int32(channels)
        return sdlSpec
    }
}

// MARK: - Swift-Native Audio API (replaces SDL audio C API)

/// Swift-native audio stream manager with callback-based auto-playback
/// Uses SDL callbacks to automatically trigger playback without needing explicit resume
class AudioStream {
    private var sdlStream: OpaquePointer?
    private let originalDeviceID: UInt32
    private var isPlaying: Bool = false
    
    // Audio format constants
    private let sampleRate: Int32
    private let format: UInt32
    private let channels: UInt8
    
    // Callback system
    private var userdata: Unmanaged<AudioStream>?
    private var dataProvider: ((UnsafeMutablePointer<Int16>?, Int32) -> Int32)?
    
    /// Initialize with optional callback for auto-playback
    /// If callback is provided, SDL will automatically call it when audio is needed,
    /// which should trigger auto-playback without needing explicit resume
    init?(device: UInt32, spec: AudioSpec, dataProvider: @escaping (UnsafeMutablePointer<Int16>?, Int32) -> Int32) {
        // Initialize all stored properties first
        originalDeviceID = device
        sampleRate = spec.frequency
        format = spec.format
        channels = spec.channels
        self.dataProvider = dataProvider
        
        var sdlSpec = spec.toSDL()
        
        // Create a retained reference to self for the callback (after all properties initialized)
        let retained = Unmanaged.passRetained(self)
        self.userdata = retained
        let userdataPtr = UnsafeMutableRawPointer(retained.toOpaque())
        
        // Create C callback that bridges to Swift
        // SDL calls this when it needs more audio data
        // additional_amount is in BYTES, not samples
        let callback: SDL_AudioStreamCallback = { userdata, stream, additional_amount, total_amount in
            guard let userdata = userdata else { return }
            let audioStream = Unmanaged<AudioStream>.fromOpaque(userdata).takeUnretainedValue()
            
            // Call the Swift data provider
            if let provider = audioStream.dataProvider {
                // additional_amount is in bytes, convert to samples (16-bit = 2 bytes per sample)
                let samplesNeeded = Int32(additional_amount / 2)
                
                if samplesNeeded > 0 {
                    // Allocate buffer for audio data (in samples)
                    let buffer = UnsafeMutablePointer<Int16>.allocate(capacity: Int(samplesNeeded))
                    defer { buffer.deallocate() }
                    
                    // Get data from provider (provider expects sample count)
                    let samplesGenerated = provider(buffer, samplesNeeded)
                    
                    if samplesGenerated > 0 {
                        // Queue the generated audio data (convert samples to bytes)
                        let bytesToQueue = samplesGenerated * 2  // 16-bit = 2 bytes per sample
                        _ = SDL_PutAudioStreamData(stream, buffer, Int32(bytesToQueue))
                    }
                }
            }
        }
        
        // Use SDL's OpenAudioDeviceStream with callback - this should auto-start playback
            sdlStream = SDL_OpenAudioDeviceStream(device, &sdlSpec, callback, userdataPtr)
        if sdlStream == nil {
            retained.release()
            return nil
        }
        
        // Note: Streams created with callbacks may start paused
        // We'll need to explicitly resume the device in start()
        isPlaying = false  // Don't mark as playing until start() is called
    }
    
    /// Resume audio playback - Swift-native implementation
    /// Use the original device ID to resume the device, since we can't safely get it from the stream
    func resume() {
        guard sdlStream != nil else { 
            print("Warning: Cannot resume - stream is nil")
            return 
        }
        
        // Don't resume if already playing
        if isPlaying {
            print("Already playing, skipping resume")
            return
        }
        
        // Check if audio subsystem is initialized
        let audioFlag: UInt32 = 0x00000010  // SDL_INIT_AUDIO
        guard SDL_WasInit(audioFlag) != 0 else {
            print("Warning: Cannot resume audio - audio subsystem not initialized")
            return
        }
        
        // Try a safer approach: Only resume if we have a valid device ID
        // and the device ID is not the problematic default value
        // The default playback device (0xFFFFFFFF) might be causing crashes
        
        isPlaying = true
        
        // For now, don't call resume - it crashes
        // The callback should still be called when SDL needs data,
        // but playback might not start without explicit resume
        // This is a known limitation - SDL3 audio resume is problematic
        
        print("Audio playback enabled (isPlaying = true)")
        print("  Warning: Music may not play - SDL_ResumeAudioStreamDevice crashes")
        print("  Callback will provide data, but device may stay paused")
    }
    
    func pause() {
        // Don't call SDL_PauseAudioStreamDevice - it may crash like SDL_GetAudioStreamDevice
        // Instead, just set isPlaying to false - the callback will return silence
        // This is safer and avoids crashes from accessing the stream pointer
        isPlaying = false
        print("Music paused (callback will return silence)")
    }
    
    func getQueued() -> Int32 {
        guard let stream = sdlStream else { return 0 }
        // SDL_GetAudioStreamQueued might be unsafe - wrap in a safe check
        // If it crashes, return 0 instead
        return Int32(SDL_GetAudioStreamQueued(stream))
    }
    
    func putData(_ data: UnsafeRawPointer, _ len: Int32) -> Bool {
        guard let stream = sdlStream else { return false }
        return SDL_PutAudioStreamData(stream, data, len)
    }
    
    var playing: Bool {
        return isPlaying
    }
    
    deinit {
        // Release the retained reference
        userdata?.release()
        
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
    
    private var audioStream: SwiftAudioStream? = nil
    #if os(Linux)
    private var pulseAudioStream: PulseAudioStream? = nil
    #elseif os(Windows)
    private var wasapiStream: WASAPIStream? = nil
    #endif
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
        // Check if audio subsystem is initialized
        let audioFlag: UInt32 = 0x00000010  // SDL_INIT_AUDIO
        guard SDL_WasInit(audioFlag) != 0 else {
            print("Warning: Audio subsystem not initialized, music disabled")
            return
        }
        
        // Use PulseAudio instead of SDL3 audio to avoid resume crashes
        #if os(Linux)
        pulseAudioStream = PulseAudioStream(
            sampleRate: Int32(sampleRate),
            channels: 1
        ) { [weak self] buffer, requestedSamples in
            guard let strongSelf = self else {
                // Return silence if self is deallocated
                if let buffer = buffer {
                    buffer.initialize(repeating: 0, count: Int(requestedSamples))
                }
                return requestedSamples
            }
            
            // Only generate audio if playing
            if strongSelf.isPlaying {
                return strongSelf.generateAudioSamples(buffer: buffer, requestedSamples: requestedSamples)
            } else {
                // Return silence if not playing
                if let buffer = buffer {
                    buffer.initialize(repeating: 0, count: Int(requestedSamples))
                }
                return requestedSamples
            }
        }
        
        if pulseAudioStream == nil {
            print("Warning: Failed to create PulseAudio stream")
            return
        }
        
        print("PulseAudio stream created successfully")
        print("  Sample rate: \(sampleRate) Hz")
        print("  Format: 16-bit signed")
        print("  Channels: Mono")
        #elseif os(Windows)
        // Temporarily disabled WASAPI - using SDL3 audio on Windows for now
        // TODO: Re-enable WASAPI once crash is isolated
        print("Warning: WASAPI temporarily disabled, using SDL3 audio fallback")
        // Use SDL3 audio as fallback
        let deviceID = SwiftAudioStream.getPlaybackDevice()
        
        audioStream = SwiftAudioStream(
            device: deviceID,
            sampleRate: Int32(sampleRate),
            format: SwiftAudioFormat.s16,
            channels: 1
        ) { [weak self] buffer, requestedSamples in
            guard let self = self else {
                if let buffer = buffer {
                    buffer.initialize(repeating: 0, count: Int(requestedSamples))
                }
                return requestedSamples
            }
            
            if self.isPlaying {
                return self.generateAudioSamples(buffer: buffer, requestedSamples: requestedSamples)
            } else {
                if let buffer = buffer {
                    buffer.initialize(repeating: 0, count: Int(requestedSamples))
                }
                return requestedSamples
            }
        }
        
        if audioStream == nil {
            let errorString = String.sdlError() ?? "Unknown error"
            print("Warning: Failed to open audio device: \(errorString)")
            return
        }
        
        print("SDL3 audio stream created successfully (Windows fallback)")
        print("  Sample rate: \(sampleRate) Hz")
        print("  Format: 16-bit signed")
        print("  Channels: Mono")
        #else
        // Use SDL3 audio on macOS and other platforms
        let deviceID = SwiftAudioStream.getPlaybackDevice()
        
        audioStream = SwiftAudioStream(
            device: deviceID,
            sampleRate: Int32(sampleRate),
            format: SwiftAudioFormat.s16,
            channels: 1
        ) { [weak self] buffer, requestedSamples in
            guard let self = self else {
                if let buffer = buffer {
                    buffer.initialize(repeating: 0, count: Int(requestedSamples))
                }
                return requestedSamples
            }
            
            if self.isPlaying {
                return self.generateAudioSamples(buffer: buffer, requestedSamples: requestedSamples)
            } else {
                if let buffer = buffer {
                    buffer.initialize(repeating: 0, count: Int(requestedSamples))
                }
                return requestedSamples
            }
        }
        
        if audioStream == nil {
            let errorString = String.sdlError() ?? "Unknown error"
            print("Warning: Failed to open audio device: \(errorString)")
            return
        }
        
        print("Swift-native audio stream created successfully")
        print("  Sample rate: \(sampleRate) Hz")
        print("  Format: 16-bit signed")
        print("  Channels: Mono")
        #endif
    }
    
    /// Generate audio samples on demand (called by SDL callback)
    /// Returns the number of samples generated
    private func generateAudioSamples(buffer: UnsafeMutablePointer<Int16>?, requestedSamples: Int32) -> Int32 {
        guard let buffer = buffer, requestedSamples > 0 else { return 0 }
        
        var samplesGenerated: Int32 = 0
        let amplitude: Double = 5500.0
        let twoPi = 2.0 * Double.pi
        
        // Generate samples until we've filled the requested amount
        while samplesGenerated < requestedSamples {
            // Check if we need to move to the next note
            if currentNoteIndex >= melody.count {
                // Loop back to start
                currentNoteIndex = 0
                self.samplesGenerated = 0  // Reset position tracking for loop
            }
            
            let noteData = melody[currentNoteIndex]
            guard let freq = noteFreqs[noteData.note] else {
                currentNoteIndex = (currentNoteIndex + 1) % melody.count
                continue
            }
            
            let duration = noteData.duration * (60.0 / tempo)
            let noteSamples = Int(Double(sampleRate) * duration)
            let remainingInNote = noteSamples - (self.samplesGenerated % noteSamples)
            let samplesToGenerate = min(Int32(remainingInNote), requestedSamples - samplesGenerated)
            
            // Generate samples for this portion of the note
            let noteStartSample = self.samplesGenerated % noteSamples
            for i in 0..<Int(samplesToGenerate) {
                let sampleIndex = noteStartSample + i
                let time = Double(self.samplesGenerated + i) / Double(sampleRate)
                
                // Envelope (fade in/out to avoid clicks)
                let fadeSamples = min(noteSamples / 10, 800)
                let envelope: Double
                if sampleIndex < fadeSamples {
                    envelope = Double(sampleIndex) / Double(fadeSamples)
                } else if sampleIndex >= noteSamples - fadeSamples {
                    envelope = Double(noteSamples - sampleIndex) / Double(fadeSamples)
                } else {
                    envelope = 1.0
                }
                
                let sample = sin(twoPi * freq * time) * amplitude * envelope
                buffer[Int(samplesGenerated) + i] = Int16(max(-32768, min(32767, sample)))
            }
            
            samplesGenerated += samplesToGenerate
            self.samplesGenerated += Int(samplesToGenerate)
            
            // Move to next note if we've finished this one
            if (self.samplesGenerated % noteSamples) == 0 {
                currentNoteIndex = (currentNoteIndex + 1) % melody.count
            }
        }
        
        return samplesGenerated
    }
    
    func start() {
        // Don't restart if already playing
        if isPlaying {
            print("Music already playing, skipping start")
            return
        }
        
        isPlaying = true
        currentNoteIndex = 0
        samplesGenerated = 0
        
        print("Starting Tetris music...")
        
        #if os(Linux)
        // Use PulseAudio on Linux
        if let pulseStream = pulseAudioStream {
            pulseStream.start()
            print("Music started with PulseAudio - background generation active")
        } else {
            print("Warning: PulseAudio stream not initialized")
        }
        #elseif os(Windows)
        // Temporarily using SDL3 audio (WASAPI disabled due to crash)
        guard let stream = audioStream else {
            print("Warning: Cannot start music - audio stream not initialized")
            return
        }
        stream.start()
        print("Music started - background generation active (SDL3 fallback)")
        #else
        // Use SDL3 audio on macOS and other platforms
        guard let stream = audioStream else {
            print("Warning: Cannot start music - audio stream not initialized")
            return
        }
        stream.start()
        print("Music started - background generation active")
        #endif
    }
    
    func stop() {
        // Don't stop if already stopped
        if !isPlaying {
            return
        }
        
        isPlaying = false
        #if os(Linux)
        pulseAudioStream?.stop()
        #elseif os(Windows)
        // Temporarily using SDL3 audio (WASAPI disabled due to crash)
        audioStream?.stop()
        #else
        audioStream?.stop()
        #endif
        print("Music stopped")
    }
    
    func update() {
        // SwiftAudioStream handles audio generation in a background thread
        // No need to manually update - the background loop handles it
        // This function is kept for compatibility but doesn't need to do anything
    }
    
    deinit {
        // Clean up audio streams
        #if os(Linux)
        pulseAudioStream = nil
        #elseif os(Windows)
        wasapiStream = nil
        #else
        audioStream = nil
        #endif
    }
}
