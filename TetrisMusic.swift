import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif
import CSDL2

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
    
    private var audioDevice: UInt32 = 0
    private var sampleRate: Int = 44100
    private var isPlaying = false
    private var samplesGenerated = 0
    
    // Tetris theme melody - Korobeiniki (simplified first part, loops continuously)
    // Format: (note, duration in beats)
    private let melody: [(note: String, duration: Double)] = [
        ("E5", 0.5), ("B4", 0.5), ("C5", 0.5), ("D5", 0.5),
        ("C5", 0.5), ("B4", 0.5), ("A4", 1.0),
        ("A4", 0.5), ("C5", 0.5), ("E5", 0.5), ("D5", 0.5),
        ("C5", 1.0), ("B4", 1.0),
        ("C5", 0.5), ("D5", 0.5), ("E5", 1.0),
        ("C5", 1.0), ("A4", 1.0), ("A4", 1.0),
        ("D5", 1.0), ("F5", 1.0), ("A5", 1.0),
        ("G5", 1.0), ("F5", 1.0), ("E5", 1.5),
        ("C5", 0.5), ("E5", 1.0), ("D5", 0.5),
        ("C5", 1.0), ("B4", 1.0), ("B4", 0.5), ("C5", 0.5),
        ("D5", 1.0), ("E5", 1.0), ("C5", 1.0), ("A4", 1.0), ("A4", 1.0)
    ]
    
    private let tempo: Double = 144.0 // Beats per minute (matches classic Tetris tempo)
    private var currentNoteIndex = 0
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        var desired = SDL_AudioSpec()
        desired.freq = Int32(sampleRate)
        desired.format = UInt16(AUDIO_S16SYS)
        desired.channels = 1
        desired.samples = 4096
        desired.callback = nil // Use queue-based audio
        
        var obtained = SDL_AudioSpec()
        audioDevice = SDL_OpenAudioDevice(nil, 0, &desired, &obtained, 0)
        if audioDevice == 0 {
            if let error = SDL_GetError() {
                let errorString = String(cString: error)
                print("Warning: Failed to open audio device: \(errorString)")
            } else {
                print("Warning: Failed to open audio device (unknown error)")
            }
            return
        }
        
        sampleRate = Int(obtained.freq)
        SDL_PauseAudioDevice(audioDevice, 0) // Start playback
    }
    
    func start() {
        guard audioDevice != 0 else { return }
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
        guard isPlaying, audioDevice != 0 else { return }
        
        // Keep the audio queue filled (generate ahead)
        let queuedSize = SDL_GetQueuedAudioSize(audioDevice)
        let bytesPerSecond = sampleRate * 2 // sampleRate * 2 bytes (16-bit) * 1 channel
        let targetQueueSize = bytesPerSecond / 4 // 250ms buffer
        
        if UInt32(queuedSize) < targetQueueSize {
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
        
        let amplitude: Double = 14000.0 // 16-bit audio, use ~43% of range for pleasant volume
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
        let _ = samples.withUnsafeBufferPointer { buffer in
            SDL_QueueAudio(audioDevice, buffer.baseAddress, UInt32(samples.count * 2))
        }
        
        // Move to next note
        currentNoteIndex = (currentNoteIndex + 1) % melody.count
    }
    
    deinit {
        if audioDevice != 0 {
            SDL_CloseAudioDevice(audioDevice)
        }
    }
}
