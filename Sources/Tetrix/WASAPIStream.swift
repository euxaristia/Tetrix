import Foundation
#if os(Windows)
import WinSDK
#endif

// WASAPI (Windows Audio Session API) wrapper for audio playback
// This bypasses SDL3's problematic audio resume on Windows

#if os(Windows)
class WASAPIStream {
    private var context: OpaquePointer?
    private let sampleRate: Int32
    private let channels: UInt8
    private var isActive: Bool = false
    
    // Audio generation callback
    private var dataProvider: ((UnsafeMutablePointer<Int16>?, Int32) -> Int32)?
    
    // Retained self reference for C callback
    private var retainedSelf: Unmanaged<WASAPIStream>?
    
    init?(sampleRate: Int32, channels: UInt8, 
          dataProvider: @escaping (UnsafeMutablePointer<Int16>?, Int32) -> Int32) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.dataProvider = dataProvider
        
        // Create WASAPI context
        context = wasapi_audio_create(Int(sampleRate), Int(channels))
        
        if context == nil {
            print("Failed to create WASAPI context")
            return nil
        }
        
        print("WASAPI stream created successfully")
        print("  Sample rate: \(sampleRate) Hz")
        print("  Channels: \(channels)")
    }
    
    func start() {
        guard context != nil, !isActive else { return }
        
        isActive = true
        
        // Create retained reference for callback
        let retained = Unmanaged.passRetained(self)
        retainedSelf = retained
        
        // Set data provider callback
        // C callback bridge
        let callback: @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<Int16>?, Int32) -> Int32 = { userData, buffer, samples in
            guard let userData = userData else { return 0 }
            let wasapiStream = Unmanaged<WASAPIStream>.fromOpaque(userData).takeUnretainedValue()
            
            guard let provider = wasapiStream.dataProvider, wasapiStream.isActive else {
                if let buffer = buffer {
                    buffer.initialize(repeating: 0, count: Int(samples))
                }
                return samples
            }
            
            return provider(buffer, samples)
        }
        
        // Set the data provider
        let providerSet = wasapi_audio_set_data_provider(context, retained.toOpaque(), callback)
        guard providerSet != 0 else {
            retained.release()
            retainedSelf = nil
            isActive = false
            print("Warning: Failed to set WASAPI data provider")
            return
        }
        
        // Start WASAPI
        let started = wasapi_audio_start(context)
        if started == 0 {
            retained.release()
            retainedSelf = nil
            isActive = false
            print("Warning: Failed to start WASAPI audio")
            return
        }
        
        print("WASAPI stream started - background generation active")
    }
    
    func stop() {
        isActive = false
        if let ctx = context {
            wasapi_audio_stop(ctx)
        }
        retainedSelf?.release()
        retainedSelf = nil
        print("WASAPI stream stopped")
    }
    
    deinit {
        isActive = false
        if let ctx = context {
            wasapi_audio_destroy(ctx)
        }
        retainedSelf?.release()
    }
}

// C function declarations
@_silgen_name("wasapi_audio_create")
func wasapi_audio_create(_ sample_rate: Int, _ channels: Int) -> OpaquePointer?

@_silgen_name("wasapi_audio_start")
func wasapi_audio_start(_ context: OpaquePointer?) -> Int32

@_silgen_name("wasapi_audio_set_data_provider")
func wasapi_audio_set_data_provider(_ context: OpaquePointer?, _ userData: UnsafeMutableRawPointer?, _ dataProvider: @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<Int16>?, Int32) -> Int32) -> Int32

@_silgen_name("wasapi_audio_stop")
func wasapi_audio_stop(_ context: OpaquePointer?)

@_silgen_name("wasapi_audio_destroy")
func wasapi_audio_destroy(_ context: OpaquePointer?)

#endif // os(Windows)
