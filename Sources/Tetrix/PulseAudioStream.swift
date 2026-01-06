import Foundation
#if os(Linux)
import Glibc
#endif

// Minimal PulseAudio wrapper for audio playback
// This bypasses SDL3's crashing resume function

class PulseAudioStream {
    private var context: OpaquePointer?
    private let sampleRate: Int32
    private let channels: UInt8
    private var isActive: Bool = false
    
    // Audio generation callback
    private var dataProvider: ((UnsafeMutablePointer<Int16>?, Int32) -> Int32)?
    
    init?(sampleRate: Int32, channels: UInt8, 
          dataProvider: @escaping (UnsafeMutablePointer<Int16>?, Int32) -> Int32) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.dataProvider = dataProvider
        
        // Create PulseAudio context
        context = pulse_audio_create(Int(sampleRate), Int(channels), 16)  // 16 = S16LE
        
        if context == nil {
            print("Failed to create PulseAudio context")
            return nil
        }
        
        print("PulseAudio stream created successfully")
        print("  Sample rate: \(sampleRate) Hz")
        print("  Channels: \(channels)")
    }
    
    func start() {
        guard context != nil, !isActive else { return }
        
        isActive = true
        
        // Start background thread to continuously generate and write audio
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.audioGenerationLoop()
        }
        
        print("PulseAudio stream started - background generation active")
    }
    
    private func audioGenerationLoop() {
        guard let ctx = context, let provider = dataProvider else {
            print("Audio generation loop: context or provider is nil")
            return
        }
        
        print("PulseAudio generation loop started")
        let bufferSize = Int(sampleRate) / 10  // 100ms chunks
        let buffer = UnsafeMutablePointer<Int16>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        while isActive {
            let samplesToGenerate = Int32(bufferSize)
            let samplesGenerated = provider(buffer, samplesToGenerate)
            
            if samplesGenerated > 0 {
                let bytesToWrite = Int(samplesGenerated * 2)  // 16-bit = 2 bytes per sample
                let written = pulse_audio_write(ctx, buffer, bytesToWrite)
                if written == 0 {
                    print("Warning: Failed to write audio data to PulseAudio")
                }
            }
            
            // Small sleep to avoid busy-waiting
            #if os(Linux)
            usleep(10000)  // 10ms
            #else
            Thread.sleep(forTimeInterval: 0.01)
            #endif
        }
        
        // Drain any remaining audio
        _ = pulse_audio_drain(ctx)
        print("PulseAudio generation loop stopped")
    }
    
    func stop() {
        isActive = false
        print("PulseAudio stream stopped")
    }
    
    deinit {
        isActive = false
        if let ctx = context {
            pulse_audio_destroy(ctx)
        }
    }
}

// C function declarations
@_silgen_name("pulse_audio_create")
func pulse_audio_create(_ sample_rate: Int, _ channels: Int, _ format: Int) -> OpaquePointer?

@_silgen_name("pulse_audio_write")
func pulse_audio_write(_ context: OpaquePointer?, _ data: UnsafeRawPointer?, _ bytes: Int) -> Int32

@_silgen_name("pulse_audio_drain")
func pulse_audio_drain(_ context: OpaquePointer?) -> Int32

@_silgen_name("pulse_audio_destroy")
func pulse_audio_destroy(_ context: OpaquePointer?)
