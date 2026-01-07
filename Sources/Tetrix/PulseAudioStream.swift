import Foundation
#if os(Linux)
import Glibc
#endif

// Pure Swift PulseAudio wrapper for audio playback
// This bypasses SDL3's crashing resume function by directly using PulseAudio

#if os(Linux)
// PulseAudio types and constants
// Use proper C struct definitions to match PulseAudio API
// Order must match C struct: format (UInt32), rate (UInt32), channels (UInt8)
private struct pa_sample_spec {
    var format: UInt32  // pa_sample_format_t (which is UInt32)
    var rate: UInt32
    var channels: UInt8
}

private struct pa_buffer_attr {
    var maxlength: UInt32
    var tlength: UInt32
    var prebuf: UInt32
    var minreq: UInt32
    var fragsize: UInt32
}

private typealias pa_simple = OpaquePointer

// PulseAudio constants (from pulse/sample.h and pulse/def.h)
// PA_SAMPLE_S16LE is the 4th enum value (after U8=0, ALAW=1, ULAW=2)
private let PA_SAMPLE_S16LE: UInt32 = 3  // Signed 16-bit little-endian
private let PA_STREAM_PLAYBACK: Int32 = 1

// PulseAudio function declarations
@_silgen_name("pa_simple_new")
private func pa_simple_new(
    _ server: UnsafePointer<CChar>?,
    _ name: UnsafePointer<CChar>?,
    _ dir: Int32,
    _ dev: UnsafePointer<CChar>?,
    _ stream_name: UnsafePointer<CChar>?,
    _ ss: UnsafePointer<pa_sample_spec>?,
    _ map: UnsafePointer<UInt8>?,
    _ ba: UnsafePointer<pa_buffer_attr>?,
    _ error: UnsafeMutablePointer<Int32>?
) -> pa_simple?

@_silgen_name("pa_simple_write")
private func pa_simple_write(
    _ s: pa_simple?,
    _ data: UnsafeRawPointer?,
    _ bytes: Int,
    _ error: UnsafeMutablePointer<Int32>?
) -> Int32

@_silgen_name("pa_simple_drain")
private func pa_simple_drain(
    _ s: pa_simple?,
    _ error: UnsafeMutablePointer<Int32>?
) -> Int32

@_silgen_name("pa_simple_free")
private func pa_simple_free(_ s: pa_simple?)

// PulseAudio context wrapper
private class PulseAudioContext {
    var pa: pa_simple?
    let sampleRate: Int32
    let channels: UInt8
    
    init?(sampleRate: Int32, channels: UInt8) {
        self.sampleRate = sampleRate
        self.channels = channels
        
        // Create sample spec (order: format, rate, channels)
        var ss = pa_sample_spec(
            format: PA_SAMPLE_S16LE,
            rate: UInt32(sampleRate),
            channels: channels
        )
        
        // Create buffer attributes
        // These settings help prevent clicks/pops by maintaining a good buffer level
        let bytesPerSample = 2  // 16-bit = 2 bytes
        let bytesPerSecond = Int(sampleRate) * Int(channels) * bytesPerSample
        var ba = pa_buffer_attr(
            maxlength: UInt32(bytesPerSecond * 2),      // 2 seconds max buffer
            tlength: UInt32(bytesPerSecond / 5),         // 200ms target buffer (larger for stability)
            prebuf: UInt32(bytesPerSecond / 10),        // 100ms prebuffer (larger to prevent underruns)
            minreq: UInt32(bytesPerSecond / 40),        // 25ms minimum request
            fragsize: UInt32(bytesPerSecond / 40)       // 25ms fragment size
        )
        
        // Create PulseAudio stream
        var error: Int32 = 0
        let appName = "Tetrix"
        let streamName = "Tetris Music"
        
        pa = appName.withCString { appNamePtr in
            streamName.withCString { streamNamePtr in
                withUnsafePointer(to: &ss) { ssPtr in
                    withUnsafePointer(to: &ba) { baPtr in
                        pa_simple_new(
                            nil,  // server (NULL = default)
                            appNamePtr,
                            PA_STREAM_PLAYBACK,
                            nil,  // device (NULL = default)
                            streamNamePtr,
                            ssPtr,
                            nil,  // channel map (NULL = default)
                            baPtr,
                            &error
                        )
                    }
                }
            }
        }
        
        if pa == nil {
            // Error code 3 = PA_ERR_INVALID (invalid argument, likely struct layout issue)
            // Error code 6 = PA_ERR_CONNECTIONREFUSED (PulseAudio server not running)
            let errorNames: [Int32: String] = [
                0: "PA_OK",
                1: "PA_ERR_ACCESS",
                2: "PA_ERR_COMMAND", 
                3: "PA_ERR_INVALID",
                4: "PA_ERR_EXIST",
                5: "PA_ERR_NOENTITY",
                6: "PA_ERR_CONNECTIONREFUSED",
                7: "PA_ERR_PROTOCOL",
                8: "PA_ERR_TIMEOUT"
            ]
            let errorName = errorNames[error] ?? "UNKNOWN(\(error))"
            print("Failed to create PulseAudio stream: error code \(error) (\(errorName))")
            print("  Sample rate: \(sampleRate), Channels: \(channels)")
            if error == 6 {
                print("  Hint: PulseAudio server may not be running. Try: pulseaudio --start")
            } else if error == 3 {
                print("  Hint: Invalid argument - struct layout may not match C API")
            }
            return nil
        }
    }
    
    func write(data: UnsafeRawPointer, bytes: Int) -> Bool {
        guard let pa = pa else { return false }
        
        var error: Int32 = 0
        let result = pa_simple_write(pa, data, bytes, &error)
        
        if result < 0 {
            print("Failed to write to PulseAudio: error code \(error)")
            return false
        }
        
        return true
    }
    
    func drain() -> Bool {
        guard let pa = pa else { return false }
        
        var error: Int32 = 0
        let result = pa_simple_drain(pa, &error)
        
        if result < 0 {
            print("Failed to drain PulseAudio: error code \(error)")
            return false
        }
        
        return true
    }
    
    deinit {
        if let pa = pa {
            pa_simple_free(pa)
        }
    }
}
#endif

class PulseAudioStream {
    #if os(Linux)
    private var context: PulseAudioContext?
    #else
    private var context: Any? = nil  // Placeholder for non-Linux
    #endif
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
        
        #if os(Linux)
        // Create PulseAudio context
        context = PulseAudioContext(sampleRate: sampleRate, channels: channels)
        
        if context == nil {
            print("Failed to create PulseAudio context")
            return nil
        }
        
        print("PulseAudio stream created successfully")
        print("  Sample rate: \(sampleRate) Hz")
        print("  Channels: \(channels)")
        #else
        // PulseAudio is only available on Linux
        print("PulseAudio is not available on this platform")
        return nil
        #endif
    }
    
    func start() {
        #if os(Linux)
        guard context != nil, !isActive else { return }
        
        isActive = true
        
        // Start background thread to continuously generate and write audio
        // Use [self] capture to ensure self is strongly referenced during audio generation
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            self.audioGenerationLoop()
        }
        
        print("PulseAudio stream started - background generation active")
        #endif
    }
    
    #if os(Linux)
    private func audioGenerationLoop() {
        guard let ctx = context, let provider = dataProvider else {
            print("Audio generation loop: context or provider is nil")
            return
        }
        
        print("PulseAudio generation loop started")
        // Generate smaller chunks more frequently to keep buffer well-fed
        // 25ms chunks = sampleRate / 40 - this keeps the buffer filled without underruns
        let bufferSize = Int(sampleRate) / 40  // 25ms chunks
        let buffer = UnsafeMutablePointer<Int16>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        while isActive {
            let samplesToGenerate = Int32(bufferSize)
            let samplesGenerated = provider(buffer, samplesToGenerate)
            
            if samplesGenerated > 0 {
                // Calculate bytes: samples * channels * bytes_per_sample
                // For mono (1 channel), 16-bit (2 bytes): samples * 1 * 2
                let bytesToWrite = Int(samplesGenerated) * Int(channels) * 2
                
                // Write data to PulseAudio
                let success = ctx.write(data: buffer, bytes: bytesToWrite)
                if !success {
                    print("Warning: Failed to write audio data to PulseAudio")
                    // Small delay on error to avoid tight loop
                    usleep(10000)
                }
            } else if samplesGenerated == 0 {
                // Provider returned 0 samples - might be pausing or issue
                // Fill with silence to prevent clicks
                buffer.initialize(repeating: 0, count: bufferSize)
                let bytesToWrite = Int(bufferSize) * Int(channels) * 2
                _ = ctx.write(data: buffer, bytes: bytesToWrite)
            }
            
            // Sleep slightly less than buffer duration to keep buffer filled
            // 25ms chunks, sleep 20ms to maintain buffer level and prevent underruns
            usleep(20000)  // 20ms
        }
        
        // Drain any remaining audio
        _ = ctx.drain()
        print("PulseAudio generation loop stopped")
    }
    #endif
    
    func stop() {
        isActive = false
        print("PulseAudio stream stopped")
    }
    
    deinit {
        isActive = false
        #if os(Linux)
        context = nil  // Will call deinit and free PulseAudio resources
        #endif
    }
}
