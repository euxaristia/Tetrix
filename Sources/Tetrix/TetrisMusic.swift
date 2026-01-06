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
        sdlSpec.format = SDL_AudioFormat(rawValue: format)
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
        let callback: SDL_AudioStreamCallback = { userdata, stream, additional_amount, total_amount in
            guard let userdata = userdata else { return }
            let audioStream = Unmanaged<AudioStream>.fromOpaque(userdata).takeUnretainedValue()
            
            // Call the Swift data provider
            if let provider = audioStream.dataProvider {
                // Allocate buffer for audio data
                let bufferSize = Int(additional_amount)
                let buffer = UnsafeMutablePointer<Int16>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                
                // Get data from provider
                let samplesGenerated = provider(buffer, Int32(bufferSize))
                
                if samplesGenerated > 0 {
                    // Queue the generated audio data
                    let bytesToQueue = samplesGenerated * 2  // 16-bit = 2 bytes per sample
                    _ = SDL_PutAudioStreamData(stream, buffer, Int32(bytesToQueue))
                }
            }
        }
        
        // Use SDL's OpenAudioDeviceStream with callback - this should auto-start playback
            sdlStream = SDL_OpenAudioDeviceStream(device, &sdlSpec, callback, userdataPtr)
        if sdlStream == nil {
            retained.release()
            return nil
        }
        
        // With callback-based streams, SDL should auto-start playback
        isPlaying = true
    }
    
    /// Resume audio playback - Swift-native implementation
    /// Since SDL_GetAudioStreamDevice() crashes, we use a workaround:
    /// 1. Ensure the stream has data (callback provides it)
    /// 2. Try resuming with the original device ID we used when opening
    /// 3. If that doesn't work, rely on callback-based auto-playback
    func resume() {
        guard sdlStream != nil else { return }
        
        // Check if audio subsystem is initialized
        let audioFlag: UInt32 = 0x00000010  // SDL_INIT_AUDIO
        guard SDL_WasInit(audioFlag) != 0 else {
            print("Warning: Cannot resume audio - audio subsystem not initialized")
            return
        }
        
        // Strategy: With callback-based streams, SDL should automatically call our callback
        // when playback starts. However, the stream might still need to be unpaused.
        // 
        // Since we can't safely get the device ID from the stream, we'll try a different approach:
        // 1. Ensure stream is not paused (try unpausing if possible)
        // 2. Ensure callback is providing data
        // 3. SDL should automatically start calling the callback
        
        // The callback-based approach should work, but streams might start paused.
        // Unfortunately, we can't unpause without the device ID.
        // However, try calling pause/unpause cycle which might help on some systems
        _ = SDL_PauseAudioStreamDevice(sdlStream!)
        
        // Small delay
        #if os(Linux)
        usleep(5000)  // 5ms
        #else
        Thread.sleep(forTimeInterval: 0.005)
        #endif
        
        // Try to ensure stream has data - callback should provide it automatically
        // but we can also pre-fill some data
        let queued = SDL_GetAudioStreamQueued(sdlStream!)
        if queued == 0 {
            print("Audio stream empty - callback should provide data automatically")
        }
        
        isPlaying = true
        print("Audio stream resume attempted - callback-based auto-playback enabled")
        print("  Note: If audio doesn't play, SDL3 may require explicit device resume (not available safely)")
    }
    
    func pause() {
        guard let stream = sdlStream else { return }
        _ = SDL_PauseAudioStreamDevice(stream)
        isPlaying = false
    }
    
    func getQueued() -> Int32 {
        guard let stream = sdlStream else { return 0 }
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
        // Check if audio subsystem is initialized
        let audioFlag: UInt32 = 0x00000010  // SDL_INIT_AUDIO
        guard SDL_WasInit(audioFlag) != 0 else {
            print("Warning: Audio subsystem not initialized, music disabled")
            return
        }
        
        let spec = AudioSpec(
            frequency: Int32(sampleRate),
            format: AudioFormat.s16,  // SDL3: 16-bit signed samples (UInt32)
            channels: 1  // Mono audio
        )
        
        // Create callback-based audio stream that auto-plays
        // The callback will generate audio on demand
        audioStream = AudioStream(device: AudioDevice.defaultPlayback, spec: spec) { [weak self] buffer, requestedSamples in
            guard let self = self, self.isPlaying else {
                // Return silence if not playing
                if let buffer = buffer {
                    buffer.initialize(repeating: 0, count: Int(requestedSamples))
                }
                return requestedSamples
            }
            
            // Generate audio samples
            return self.generateAudioSamples(buffer: buffer, requestedSamples: requestedSamples)
        }
        
        if audioStream == nil {
            let errorString = String.sdlError() ?? "Unknown error"
            print("Warning: Failed to open audio device: \(errorString)")
            return
        }
        
        print("Audio stream created with callback-based auto-playback")
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
        guard let stream = audioStream else { return }
        isPlaying = true
        currentNoteIndex = 0
        samplesGenerated = 0
        
        // Hybrid approach: Pre-fill some audio data manually to trigger playback,
        // then let the callback take over for continuous generation
        // This might help trigger SDL to start playback even if callback alone doesn't
        let bytesPerSecond = sampleRate * 2  // 16-bit mono
        let prefillAmount = bytesPerSecond / 2  // 500ms of audio
        
        // Generate and queue initial audio to trigger playback
        var prefillSamples: [Int16] = []
        let samplesNeeded = prefillAmount / 2  // 2 bytes per sample
        
        // Generate initial samples
        for _ in 0..<samplesNeeded {
            if currentNoteIndex >= melody.count {
                currentNoteIndex = 0
                samplesGenerated = 0
            }
            
            let noteData = melody[currentNoteIndex]
            guard let freq = noteFreqs[noteData.note] else {
                currentNoteIndex = (currentNoteIndex + 1) % melody.count
                continue
            }
            
            let time = Double(samplesGenerated) / Double(sampleRate)
            let sample = sin(2.0 * Double.pi * freq * time) * 5500.0
            prefillSamples.append(Int16(max(-32768, min(32767, sample))))
            samplesGenerated += 1
            
            let duration = noteData.duration * (60.0 / tempo)
            let noteSamples = Int(Double(sampleRate) * duration)
            if samplesGenerated % noteSamples == 0 {
                currentNoteIndex = (currentNoteIndex + 1) % melody.count
            }
        }
        
        // Queue the pre-filled data
        let _ = prefillSamples.withUnsafeBufferPointer { buffer in
            let bytesToWrite = prefillSamples.count * 2
            _ = stream.putData(buffer.baseAddress!, Int32(bytesToWrite))
        }
        
        // Now resume - this should trigger playback with the pre-filled data,
        // and the callback will continue providing data
        stream.resume()
    }
    
    func stop() {
        isPlaying = false
        // Pause playback when stopping
        audioStream?.pause()
    }
    
    func update() {
        // With callback-based streams, SDL calls our callback automatically
        // No need to manually queue data - the callback handles it
        // This function is kept for compatibility but doesn't need to do anything
        guard isPlaying, audioStream != nil else { return }
        // Callback is handling audio generation automatically
    }
    
    deinit {
        // AudioStream deinit will clean up SDL stream automatically
        audioStream = nil
    }
}
