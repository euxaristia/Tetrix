import Foundation
import SwiftSDL
import CSDL3
#if os(Linux)
import Glibc
#endif

// MARK: - Swift-Native Audio Types (replaces SDL audio C types)

// Note: AudioStream and related types are now provided by SwiftSDL

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
        // Don't initialize audio here - wait until SDL is initialized
        // setupAudio() will be called lazily when music is first started
    }
    
    private func setupAudio() {
        // Don't reinitialize if already set up
        if audioStream != nil {
            return
        }
        
        // Check if audio subsystem is initialized
        let audioFlag: UInt32 = 0x00000010  // SDL_INIT_AUDIO
        guard SDL_WasInit(audioFlag) != 0 else {
            print("Warning: Audio subsystem not initialized, music disabled")
            return
        }
        
        // Use SwiftSDL's unified AudioStream API (handles platform differences)
        audioStream = AudioStream(
            sampleRate: Int32(sampleRate),
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
            print("Warning: Failed to create audio stream")
            return
        }
        
        print("Audio stream created successfully")
        print("  Sample rate: \(sampleRate) Hz")
        print("  Format: 16-bit signed")
        print("  Channels: Mono")
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
        // Don't restart if already playing - this prevents issues when start() is called multiple times
        if isPlaying {
            print("Music already playing, skipping start (isPlaying=\(isPlaying))")
            return
        }
        
        print("Starting Tetris music...")
        
        // Initialize audio stream if not already done (lazy initialization after SDL is ready)
        if audioStream == nil {
            setupAudio()
        }
        
        // Reset state before starting
        currentNoteIndex = 0
        samplesGenerated = 0
        
        // Use SwiftSDL's unified AudioStream API
        guard let stream = audioStream else {
            print("Warning: Cannot start music - audio stream not initialized")
            isPlaying = false
            return
        }
        // Set isPlaying AFTER successfully starting the stream
        stream.start()
        isPlaying = true
        print("Music started - background generation active")
    }
    
    // Public property to check if music is playing
    var isCurrentlyPlaying: Bool {
        return isPlaying
    }
    
    func stop() {
        // Don't stop if already stopped
        if !isPlaying {
            return
        }
        
        isPlaying = false
        audioStream?.stop()
        print("Music stopped")
    }
    
    func update() {
        // SwiftAudioStream handles audio generation in a background thread
        // No need to manually update - the background loop handles it
        // This function is kept for compatibility but doesn't need to do anything
    }
    
    deinit {
        // Clean up audio stream
        audioStream = nil
    }
}
