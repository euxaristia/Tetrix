import Foundation
import CSDL3

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
    
    private var audioStream: OpaquePointer? = nil  // SDL_AudioStream*
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
        var spec = SDL_AudioSpec()
        spec.freq = Int32(sampleRate)
        spec.format = SDL_AUDIO_S16  // SDL3: 16-bit signed samples
        spec.channels = 1  // Mono audio
        
        // SDL3: Use SDL_OpenAudioDeviceStream to open device and create stream
        // Pass nil for callback - we'll queue data manually
        audioStream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, nil, nil)
        
        if audioStream == nil {
            let errorString = String.sdlError() ?? "Unknown error"
            print("Warning: Failed to open audio device: \(errorString)")
            return
        }
        
        // SDL3: Device starts paused, resume to start playback
        SDL_ResumeAudioStreamDevice(audioStream)
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
        // SDL3: Use SDL_GetAudioStreamQueued to check queued data size
        let queuedSize = SDL_GetAudioStreamQueued(stream)
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
        
        // SDL3: Use SDL_PutAudioStreamData to queue audio data
        guard let stream = audioStream else { return }
        let _ = samples.withUnsafeBufferPointer { buffer in
            let bytesToWrite = samples.count * 2  // 2 bytes per Int16 sample
            SDL_PutAudioStreamData(stream, buffer.baseAddress, Int32(bytesToWrite))
        }
        
        // Move to next note
        currentNoteIndex = (currentNoteIndex + 1) % melody.count
    }
    
    deinit {
        if let stream = audioStream {
            // SDL3: Destroying the stream also closes the device
            SDL_DestroyAudioStream(stream)
        }
    }
}
