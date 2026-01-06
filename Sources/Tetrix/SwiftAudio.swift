import Foundation
#if os(Linux)
import Glibc
#endif
import CSDL3

// MARK: - Swift-Native Audio API
// A safe wrapper around SDL3 audio that avoids the crashing resume/pause functions

/// Swift-native audio stream that manually generates and queues audio data
/// Uses real device IDs instead of default to avoid resume crashes
class SwiftAudioStream {
    private var sdlStream: OpaquePointer?
    private let deviceID: UInt32
    private let sampleRate: Int32
    private let format: UInt32
    private let channels: UInt8
    private var isActive: Bool = false
    
    /// Get a device ID to use
    /// Since device enumeration isn't available, we'll use the default
    /// and try a workaround with the stream pointer
    static func getPlaybackDevice() -> UInt32 {
        // Use default device - we'll try to work around the resume crash
        return SwiftAudioDevice.defaultPlayback
    }
    
    // Audio generation callback
    private var dataProvider: ((UnsafeMutablePointer<Int16>?, Int32) -> Int32)?
    
    // Retained reference for callback
    private var userdata: Unmanaged<SwiftAudioStream>?
    
    
    /// Initialize audio stream
    init?(device: UInt32, sampleRate: Int32, format: UInt32, channels: UInt8, 
          dataProvider: @escaping (UnsafeMutablePointer<Int16>?, Int32) -> Int32) {
        self.deviceID = device
        self.sampleRate = sampleRate
        self.format = format
        self.channels = channels
        self.dataProvider = dataProvider
        
        // Create SDL audio spec
        var sdlSpec = SDL_AudioSpec()
        sdlSpec.freq = sampleRate
        #if os(Windows)
        sdlSpec.format = SDL_AudioFormat(rawValue: Int32(format))
        #else
        sdlSpec.format = SDL_AudioFormat(rawValue: UInt32(format))
        #endif
        sdlSpec.channels = Int32(channels)
        
        // Create stream WITH a working callback
        // The callback will provide data, which should help trigger playback
        // We'll also manually queue data in background thread for reliability
        let retained = Unmanaged.passRetained(self)
        let userdataPtr = UnsafeMutableRawPointer(retained.toOpaque())
        
        let callback: SDL_AudioStreamCallback = { userdata, stream, additional_amount, total_amount in
            guard let userdata = userdata else { return }
            let audioStream = Unmanaged<SwiftAudioStream>.fromOpaque(userdata).takeUnretainedValue()
            
            // Call the data provider to generate audio
            if let provider = audioStream.dataProvider, audioStream.isActive {
                let samplesNeeded = Int32(additional_amount / 2)  // Convert bytes to samples
                if samplesNeeded > 0 {
                    let buffer = UnsafeMutablePointer<Int16>.allocate(capacity: Int(samplesNeeded))
                    defer { buffer.deallocate() }
                    
                    let samplesGenerated = provider(buffer, samplesNeeded)
                    if samplesGenerated > 0 {
                        let bytesToQueue = samplesGenerated * 2
                        _ = SDL_PutAudioStreamData(stream, buffer, Int32(bytesToQueue))
                    }
                }
            }
        }
        
        sdlStream = SDL_OpenAudioDeviceStream(device, &sdlSpec, callback, userdataPtr)
        
        // Store retained reference
        self.userdata = retained
        
        if sdlStream == nil {
            let errorString = String.sdlError() ?? "Unknown error"
            print("Failed to open audio stream: \(errorString)")
            return nil
        }
        
        print("SwiftAudioStream created successfully")
    }
    
    /// Start playback by queuing initial data
    /// We'll continuously queue data in a background thread
    func start() {
        guard let stream = sdlStream, !isActive else { return }
        
        isActive = true
        
        // Pre-fill buffer with audio data
        let bufferSize = Int(sampleRate) * 2  // 1 second of 16-bit mono audio
        let buffer = UnsafeMutablePointer<Int16>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        if let provider = dataProvider {
            let samplesGenerated = provider(buffer, Int32(bufferSize))
            if samplesGenerated > 0 {
                let bytesToQueue = samplesGenerated * 2
                let queued = SDL_PutAudioStreamData(stream, buffer, Int32(bytesToQueue))
                print("Pre-filled \(bytesToQueue) bytes of audio (queued: \(queued))")
            }
        }
        
        // SDL_ResumeAudioStreamDevice crashes on Windows, so we can't use it
        // Audio may not play without resume, but we can't crash the game
        // This is why native Windows audio (WASAPI) is needed
        print("Audio queued - playback may not start on Windows without resume (which crashes)")
        print("  Consider enabling WASAPI for native Windows audio support")
        
        // Start a background thread to continuously generate and queue audio
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.audioGenerationLoop()
        }
        
        print("SwiftAudioStream started - background generation active")
    }
    
    /// Background loop that continuously generates and queues audio
    private func audioGenerationLoop() {
        guard let stream = sdlStream, let provider = dataProvider else {
            print("Audio generation loop: stream or provider is nil")
            return
        }
        
        print("Audio generation loop started")
        let bufferSize = Int(sampleRate) / 10  // 100ms chunks
        let buffer = UnsafeMutablePointer<Int16>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        var loopCount = 0
        while isActive {
            // Check how much data is queued
            let queued = SDL_GetAudioStreamQueued(stream)
            
            // If queue is getting low, generate more data
            let targetQueueSize = Int32(sampleRate * 2)  // 1 second of audio
            if queued < targetQueueSize {
                let samplesToGenerate = Int32(bufferSize)
                let samplesGenerated = provider(buffer, samplesToGenerate)
                
                if samplesGenerated > 0 {
                    let bytesToQueue = samplesGenerated * 2
                    let queuedResult = SDL_PutAudioStreamData(stream, buffer, Int32(bytesToQueue))
                    if !queuedResult {
                        print("Warning: Failed to queue audio data in generation loop")
                    }
                }
            }
            
            loopCount += 1
            if loopCount % 100 == 0 {
                print("Audio loop: queued=\(queued) bytes, target=\(targetQueueSize) bytes")
            }
            
            // Small sleep to avoid busy-waiting
            #if os(Linux)
            usleep(10000)  // 10ms
            #else
            Thread.sleep(forTimeInterval: 0.01)
            #endif
        }
        
        print("Audio generation loop stopped")
    }
    
    /// Stop playback
    func stop() {
        isActive = false
        print("SwiftAudioStream stopped")
    }
    
    /// Get queued audio data amount
    func getQueued() -> Int32 {
        guard let stream = sdlStream else { return 0 }
        return Int32(SDL_GetAudioStreamQueued(stream))
    }
    
    deinit {
        isActive = false
        userdata?.release()
        if let stream = sdlStream {
            SDL_DestroyAudioStream(stream)
        }
    }
}

/// Audio format constants
enum SwiftAudioFormat {
    static var s16: UInt32 {
        return UInt32(SDL_AUDIO_S16.rawValue)
    }
}

/// Audio device constants
enum SwiftAudioDevice {
    static let defaultPlayback = SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK
}
