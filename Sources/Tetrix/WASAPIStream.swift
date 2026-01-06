import Foundation
#if os(Windows)
import WinSDK

// WASAPI (Windows Audio Session API) - Pure Swift implementation
// This bypasses SDL3's crashing resume function on Windows

class WASAPIStream {
    private var audioClient: UnsafeMutableRawPointer? // IAudioClient*
    private var renderClient: UnsafeMutableRawPointer? // IAudioRenderClient*
    private let sampleRate: Int32
    private let channels: UInt8
    private var isActive: Bool = false
    private var thread: HANDLE?
    private var stopEvent: HANDLE?
    private var bufferReadyEvent: HANDLE?
    private var bufferFrameCount: UINT32 = 0
    private var actualChannels: UInt16 = 0
    private var actualSampleRate: UInt32 = 0
    private var deviceBitsPerSample: UInt16 = 16
    private var comInitialized: Bool = false
    
    // Audio generation callback
    private var dataProvider: ((UnsafeMutablePointer<Int16>?, Int32) -> Int32)?
    
    init?(sampleRate: Int32, channels: UInt8, 
          dataProvider: @escaping (UnsafeMutablePointer<Int16>?, Int32) -> Int32) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.dataProvider = dataProvider
        
        // Create events  
        stopEvent = CreateEventW(nil, true, false, nil)  // Manual reset, initially non-signaled
        bufferReadyEvent = CreateEventW(nil, false, false, nil)  // Auto reset, initially non-signaled
        
        guard stopEvent != nil, bufferReadyEvent != nil else {
            print("WASAPI: Failed to create events")
            return nil
        }
        
        // Initialize COM
        var hr = CoInitializeEx(nil, DWORD(COINIT_MULTITHREADED.rawValue))
        comInitialized = (hr == S_OK)
        // S_FALSE means already initialized, 0x80010106 is RPC_E_CHANGED_MODE (already initialized with different mode)
        // Using unsigned comparison for HRESULT
        let hrUnsigned = UInt32(bitPattern: hr)
        if hr != S_OK && hr != S_FALSE && hrUnsigned != 0x80010106 {
            print("WASAPI: CoInitializeEx failed: 0x\(String(hr, radix: 16))")
            return nil
        }
        
        // COM GUIDs
        let CLSID_MMDeviceEnumerator = GUID(
            Data1: 0xBCDE0395,
            Data2: 0xE52F,
            Data3: 0x467C,
            Data4: (0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E)
        )
        
        let IID_IMMDeviceEnumerator = GUID(
            Data1: 0xA95664D2,
            Data2: 0x9614,
            Data3: 0x4F35,
            Data4: (0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6)
        )
        
        var IID_IAudioClient = GUID(
            Data1: 0x1CB9AD4C,
            Data2: 0xDBFA,
            Data3: 0x4C32,
            Data4: (0xB1, 0x78, 0xC2, 0xF5, 0x68, 0xA7, 0x03, 0xB2)
        )
        
        var IID_IAudioRenderClient = GUID(
            Data1: 0xF294ACFC,
            Data2: 0x3146,
            Data3: 0x4483,
            Data4: (0xA7, 0xBF, 0xAD, 0xDC, 0xA7, 0xC2, 0x60, 0xE2)
        )
        
        // Get device enumerator
        var enumerator: UnsafeMutableRawPointer?
        var clsidEnum = CLSID_MMDeviceEnumerator
        var iidEnum = IID_IMMDeviceEnumerator
        // CLSCTX_ALL = 0x17 (combination of CLSCTX_INPROC_SERVER | CLSCTX_INPROC_HANDLER | CLSCTX_LOCAL_SERVER | CLSCTX_REMOTE_SERVER)
        hr = CoCreateInstance(
            &clsidEnum,
            nil,
            DWORD(0x17),  // CLSCTX_ALL
            &iidEnum,
            &enumerator
        )
        
        guard hr == S_OK, let enumerator = enumerator else {
            print("WASAPI: CoCreateInstance failed: 0x\(String(hr, radix: 16))")
            if comInitialized { CoUninitialize() }
            return nil
        }
        
        defer {
            // Release enumerator
            let vtable = enumerator.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
            let release = unsafeBitCast(vtable[2], to: (@convention(c) (UnsafeMutableRawPointer?) -> ULONG).self)
            _ = release(enumerator)
        }
        
        // GetDefaultAudioEndpoint function pointer (vtable index 4)
        // eRender = 0, eConsole = 0
        let enumeratorVTable = enumerator.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
        let getDefaultEndpoint = unsafeBitCast(enumeratorVTable[4], to: (@convention(c) (UnsafeMutableRawPointer?, DWORD, DWORD, UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> HRESULT).self)
        
        var device: UnsafeMutableRawPointer?
        hr = getDefaultEndpoint(enumerator, 0, 0, &device)  // eRender=0, eConsole=0
        guard hr == S_OK, let device = device else {
            print("WASAPI: GetDefaultAudioEndpoint failed: 0x\(String(hr, radix: 16))")
            return nil
        }
        
        defer {
            // Release device
            let deviceVTable = device.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
            let release = unsafeBitCast(deviceVTable[2], to: (@convention(c) (UnsafeMutableRawPointer?) -> ULONG).self)
            _ = release(device)
        }
        
        // Activate function pointer (vtable index 3)
        let deviceVTable = device.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
        let activate = unsafeBitCast(deviceVTable[3], to: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<GUID>, DWORD, UnsafeMutablePointer<PROPVARIANT>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> HRESULT).self)
        
        hr = activate(device, &IID_IAudioClient, DWORD(0x17), nil, &audioClient)  // CLSCTX_ALL
        guard hr == S_OK, let audioClient = audioClient else {
            print("WASAPI: Activate failed: 0x\(String(hr, radix: 16))")
            return nil
        }
        
        // GetMixFormat function pointer (vtable index 8 for IAudioClient, after IUnknown methods 0-2)
        // IAudioClient vtable: 0=QueryInterface, 1=AddRef, 2=Release, 3=Initialize, 4=GetBufferSize, 5=GetStreamLatency, 6=GetCurrentPadding, 7=IsFormatSupported, 8=GetMixFormat
        let audioClientVTable = audioClient.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
        let getMixFormat = unsafeBitCast(audioClientVTable[8], to: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<UnsafeMutablePointer<WAVEFORMATEX>?>?) -> HRESULT).self)
        
        var mixFormat: UnsafeMutablePointer<WAVEFORMATEX>?
        hr = getMixFormat(audioClient, &mixFormat)
        guard hr == S_OK, let mixFormat = mixFormat else {
            print("WASAPI: GetMixFormat failed: 0x\(String(hr, radix: 16))")
            return nil
        }
        
        // Store actual format
        actualChannels = mixFormat.pointee.nChannels
        actualSampleRate = mixFormat.pointee.nSamplesPerSec
        deviceBitsPerSample = mixFormat.pointee.wBitsPerSample
        
        defer { CoTaskMemFree(mixFormat) }
        
        // Initialize function pointer (vtable index 3 for IAudioClient, after IUnknown methods)
        // AUDCLNT_SHAREMODE_SHARED = 0
        // REFERENCE_TIME is LONGLONG (Int64), using 0 for device default buffer size
        let initialize = unsafeBitCast(audioClientVTable[3], to: (@convention(c) (UnsafeMutableRawPointer?, DWORD, DWORD, LONGLONG, LONGLONG, UnsafePointer<WAVEFORMATEX>?, UnsafePointer<GUID>?) -> HRESULT).self)
        
        hr = initialize(audioClient, 0, 0, 0, 0, mixFormat, nil as UnsafePointer<GUID>?)  // AUDCLNT_SHAREMODE_SHARED=0
        guard hr == S_OK else {
            print("WASAPI: Initialize failed: 0x\(String(hr, radix: 16))")
            return nil
        }
        
        // SetEventHandle function pointer (vtable index 13 for IAudioClient)
        let setEventHandle = unsafeBitCast(audioClientVTable[13], to: (@convention(c) (UnsafeMutableRawPointer?, HANDLE?) -> HRESULT).self)
        _ = setEventHandle(audioClient, bufferReadyEvent)
        
        // GetBufferSize function pointer (vtable index 4 for IAudioClient)
        let getBufferSize = unsafeBitCast(audioClientVTable[4], to: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<UINT32>?) -> HRESULT).self)
        hr = getBufferSize(audioClient, &bufferFrameCount)
        guard hr == S_OK else {
            print("WASAPI: GetBufferSize failed: 0x\(String(hr, radix: 16))")
            return nil
        }
        
        // GetService function pointer (vtable index 14 for IAudioClient)
        let getService = unsafeBitCast(audioClientVTable[14], to: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<GUID>, UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> HRESULT).self)
        hr = getService(audioClient, &IID_IAudioRenderClient, &renderClient)
        guard hr == S_OK, let renderClient = renderClient else {
            print("WASAPI: GetService failed: 0x\(String(hr, radix: 16))")
            return nil
        }
        
        self.audioClient = audioClient
        self.renderClient = renderClient
        
        print("WASAPI stream created successfully")
        print("  Sample rate: \(actualSampleRate) Hz")
        print("  Channels: \(actualChannels)")
        print("  Bits per sample: \(deviceBitsPerSample)")
    }
    
    func start() {
        guard let audioClient = audioClient, !isActive else { return }
        
        isActive = true
        
        // Start function pointer (vtable index 10 for IAudioClient)
        let audioClientVTable = audioClient.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
        let start = unsafeBitCast(audioClientVTable[10], to: (@convention(c) (UnsafeMutableRawPointer?) -> HRESULT).self)
        
        let hr = start(audioClient)
        guard hr == S_OK else {
            print("WASAPI: Start failed: 0x\(String(hr, radix: 16))")
            isActive = false
            return
        }
        
        // Create audio thread
        ResetEvent(stopEvent)
        let retained = Unmanaged.passRetained(self)
        var threadId: DWORD = 0
        // C-compatible thread procedure
        let threadProc: @convention(c) (LPVOID?) -> DWORD = { param in
            WASAPIStream.audioThreadProc(param)
        }
        thread = CreateThread(nil, 0, threadProc, retained.toOpaque(), 0, &threadId)
        
        guard thread != nil else {
            let audioClientVTable = audioClient.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
            let stop = unsafeBitCast(audioClientVTable[11], to: (@convention(c) (UnsafeMutableRawPointer?) -> HRESULT).self)
            _ = stop(audioClient)
            isActive = false
            print("WASAPI: CreateThread failed")
            return
        }
        
        print("WASAPI stream started - background generation active (thread ID: \(threadId))")
        print("WASAPI: isActive=\(isActive), bufferFrameCount=\(bufferFrameCount), actualChannels=\(actualChannels)")
    }
    
    func stop() {
        isActive = false
        if let stopEvent = stopEvent {
            SetEvent(stopEvent)
        }
        if let audioClient = audioClient {
            let audioClientVTable = audioClient.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
            let stop = unsafeBitCast(audioClientVTable[11], to: (@convention(c) (UnsafeMutableRawPointer?) -> HRESULT).self)
            _ = stop(audioClient)
        }
    }
    
    deinit {
        isActive = false
        
        if let stopEvent = stopEvent {
            SetEvent(stopEvent)
        }
        
        if let thread = thread {
            WaitForSingleObject(thread, INFINITE)
            CloseHandle(thread)
        }
        
        if let audioClient = audioClient {
            let audioClientVTable = audioClient.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
            let stop = unsafeBitCast(audioClientVTable[11], to: (@convention(c) (UnsafeMutableRawPointer?) -> HRESULT).self)
            let release = unsafeBitCast(audioClientVTable[2], to: (@convention(c) (UnsafeMutableRawPointer?) -> ULONG).self)
            _ = stop(audioClient)
            _ = release(audioClient)
        }
        
        if let renderClient = renderClient {
            let renderClientVTable = renderClient.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
            let release = unsafeBitCast(renderClientVTable[2], to: (@convention(c) (UnsafeMutableRawPointer?) -> ULONG).self)
            _ = release(renderClient)
        }
        
        if let stopEvent = stopEvent {
            CloseHandle(stopEvent)
        }
        if let bufferReadyEvent = bufferReadyEvent {
            CloseHandle(bufferReadyEvent)
        }
        
        if comInitialized {
            CoUninitialize()
        }
    }
    
    // Audio thread procedure
    private static func audioThreadProc(_ param: LPVOID?) -> DWORD {
        guard let param = param else { return 0 }
        let stream = Unmanaged<WASAPIStream>.fromOpaque(param).takeUnretainedValue()
        defer { Unmanaged<WASAPIStream>.fromOpaque(param).release() }
        
        print("WASAPI audio thread started")
        
        guard let stopEvt = stream.stopEvent else {
            print("WASAPI: Stop event is nil in thread")
            return 0
        }
        
        print("WASAPI audio thread entered loop, isActive=\(stream.isActive)")
        var loopCount = 0
        while stream.isActive {
            // Poll mode - check buffer every 10ms, don't wait on buffer event since it might not be set
            // We'll use GetCurrentPadding to check if buffer needs data
            let waitResult = WaitForSingleObject(stopEvt, 10)  // Wait 10ms or until stop event
            if waitResult == WAIT_OBJECT_0 {
                print("WASAPI: Stop event signaled, exiting thread")
                break
            }
            
            // If timeout (WAIT_TIMEOUT), continue to check buffer
            // If stop event, break (already handled above)
            
            guard let audioClient = stream.audioClient,
                  let renderClient = stream.renderClient else {
                Sleep(10)
                continue
            }
            
            // GetCurrentPadding (vtable index 6 for IAudioClient)
            let audioClientVTable = audioClient.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
            let getCurrentPadding = unsafeBitCast(audioClientVTable[6], to: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<UINT32>?) -> HRESULT).self)
            
            var numFramesPadding: UINT32 = 0
            var hr = getCurrentPadding(audioClient, &numFramesPadding)
            if hr != S_OK {
                Sleep(10)
                continue
            }
            
            let numFramesAvailable = stream.bufferFrameCount - numFramesPadding
            if numFramesAvailable == 0 {
                Sleep(1)
                continue
            }
            
            // GetBuffer (vtable index 3 for IAudioRenderClient)
            let renderClientVTable = renderClient.assumingMemoryBound(to: UnsafeMutablePointer<UnsafeMutableRawPointer?>.self).pointee
            let getBuffer = unsafeBitCast(renderClientVTable[3], to: (@convention(c) (UnsafeMutableRawPointer?, UINT32, UnsafeMutablePointer<UnsafeMutablePointer<BYTE>?>?) -> HRESULT).self)
            
            var pData: UnsafeMutablePointer<BYTE>?
            hr = getBuffer(renderClient, numFramesAvailable, &pData)
            guard hr == S_OK, let pData = pData else {
                if loopCount % 1000 == 0 {
                    print("WASAPI: GetBuffer failed: 0x\(String(hr, radix: 16))")
                }
                continue
            }
            
            loopCount += 1
            if loopCount <= 5 || loopCount % 1000 == 0 {
                print("WASAPI: Audio buffer #\(loopCount), frames=\(numFramesAvailable), channels=\(stream.actualChannels), padding=\(numFramesPadding)")
            }
            
            // Generate audio
            if let provider = stream.dataProvider, stream.isActive {
                // Calculate how many samples to request from provider based on sample rate ratio
                // Provider generates at stream.sampleRate (e.g., 44.1kHz)
                // Device wants samples at stream.actualSampleRate (e.g., 48kHz)
                // So we need: providerSamples = deviceFrames * providerRate / deviceRate
                let providerSampleRate = Double(stream.sampleRate)
                let deviceSampleRate = Double(stream.actualSampleRate)
                let sampleRateRatio = providerSampleRate / deviceSampleRate
                let providerFrames = UINT32(Double(numFramesAvailable) * sampleRateRatio)
                let monoSamplesNeeded = Int32(providerFrames)  // Mono = 1 channel per frame
                
                let monoBuffer = UnsafeMutablePointer<Int16>.allocate(capacity: Int(monoSamplesNeeded))
                defer { monoBuffer.deallocate() }
                
                let monoGenerated = provider(monoBuffer, monoSamplesNeeded)
                
                if loopCount == 1 {
                    print("WASAPI: Resampling - device: \(numFramesAvailable) frames @ \(stream.actualSampleRate)Hz, provider: \(monoGenerated) samples @ \(stream.sampleRate)Hz, ratio: \(sampleRateRatio), bits: \(stream.deviceBitsPerSample)")
                }
                
                // Resample provider samples to device sample rate and convert to device channel format
                let deviceChannels = stream.actualChannels
                let providerSampleCount = Int(monoGenerated)
                let deviceFrameCount = Int(numFramesAvailable)
                
                if stream.deviceBitsPerSample == 16 {
                    // 16-bit PCM path
                    pData.withMemoryRebound(to: Int16.self, capacity: Int(numFramesAvailable) * Int(deviceChannels)) { stereoBuffer in
                        if deviceChannels == 2 {
                            // Resample and upmix mono to stereo
                            for deviceFrame in 0..<deviceFrameCount {
                                // Calculate position in provider samples
                                let providerPos = Double(deviceFrame) * sampleRateRatio
                                let providerIdx = Int(providerPos)
                                let frac = providerPos - Double(providerIdx)
                                
                                let sample: Int16
                                if providerIdx + 1 < providerSampleCount {
                                    // Linear interpolation
                                    let s0 = Int32(monoBuffer[providerIdx])
                                    let s1 = Int32(monoBuffer[providerIdx + 1])
                                    let interpolated = Int32(Double(s0) * (1.0 - frac) + Double(s1) * frac)
                                    sample = Int16(clamping: interpolated)
                                } else if providerIdx < providerSampleCount {
                                    sample = monoBuffer[providerIdx]
                                } else {
                                    sample = 0
                                }
                                
                                stereoBuffer[deviceFrame * 2] = sample      // Left channel
                                stereoBuffer[deviceFrame * 2 + 1] = sample  // Right channel
                            }
                        } else {
                            // Resample for mono or other channel counts
                            for deviceFrame in 0..<deviceFrameCount {
                                let providerPos = Double(deviceFrame) * sampleRateRatio
                                let providerIdx = Int(providerPos)
                                let frac = providerPos - Double(providerIdx)
                                
                                let sample: Int16
                                if providerIdx + 1 < providerSampleCount {
                                    let s0 = Int32(monoBuffer[providerIdx])
                                    let s1 = Int32(monoBuffer[providerIdx + 1])
                                    let interpolated = Int32(Double(s0) * (1.0 - frac) + Double(s1) * frac)
                                    sample = Int16(clamping: interpolated)
                                } else if providerIdx < providerSampleCount {
                                    sample = monoBuffer[providerIdx]
                                } else {
                                    sample = 0
                                }
                                
                                stereoBuffer[deviceFrame] = sample
                            }
                        }
                    }
                } else if stream.deviceBitsPerSample == 32 {
                    // 32-bit float path (common default mix format on Windows)
                    let scale: Float = 1.0 / 32768.0
                    pData.withMemoryRebound(to: Float.self, capacity: Int(numFramesAvailable) * Int(deviceChannels)) { floatBuffer in
                        if deviceChannels == 2 {
                            // Resample and upmix mono to stereo
                            for deviceFrame in 0..<deviceFrameCount {
                                let providerPos = Double(deviceFrame) * sampleRateRatio
                                let providerIdx = Int(providerPos)
                                let frac = providerPos - Double(providerIdx)
                                
                                let sampleInt: Int16
                                if providerIdx + 1 < providerSampleCount {
                                    let s0 = Int32(monoBuffer[providerIdx])
                                    let s1 = Int32(monoBuffer[providerIdx + 1])
                                    let interpolated = Int32(Double(s0) * (1.0 - frac) + Double(s1) * frac)
                                    sampleInt = Int16(clamping: interpolated)
                                } else if providerIdx < providerSampleCount {
                                    sampleInt = monoBuffer[providerIdx]
                                } else {
                                    sampleInt = 0
                                }
                                
                                let sampleFloat = Float(sampleInt) * scale
                                floatBuffer[deviceFrame * 2] = sampleFloat      // Left
                                floatBuffer[deviceFrame * 2 + 1] = sampleFloat  // Right
                            }
                        } else {
                            // Resample for mono or other channel counts
                            for deviceFrame in 0..<deviceFrameCount {
                                let providerPos = Double(deviceFrame) * sampleRateRatio
                                let providerIdx = Int(providerPos)
                                let frac = providerPos - Double(providerIdx)
                                
                                let sampleInt: Int16
                                if providerIdx + 1 < providerSampleCount {
                                    let s0 = Int32(monoBuffer[providerIdx])
                                    let s1 = Int32(monoBuffer[providerIdx + 1])
                                    let interpolated = Int32(Double(s0) * (1.0 - frac) + Double(s1) * frac)
                                    sampleInt = Int16(clamping: interpolated)
                                } else if providerIdx < providerSampleCount {
                                    sampleInt = monoBuffer[providerIdx]
                                } else {
                                    sampleInt = 0
                                }
                                
                                let sampleFloat = Float(sampleInt) * scale
                                floatBuffer[deviceFrame] = sampleFloat
                            }
                        }
                    }
                } else {
                    // Unsupported bit depth, just output silence
                    pData.initialize(repeating: 0, count: Int(numFramesAvailable) * Int(stream.actualChannels) * 2)
                }
            } else {
                pData.initialize(repeating: 0, count: Int(numFramesAvailable) * Int(stream.actualChannels) * 2)
            }
            
            // ReleaseBuffer (vtable index 4)
            let releaseBuffer = unsafeBitCast(renderClientVTable[4], to: (@convention(c) (UnsafeMutableRawPointer?, UINT32, DWORD) -> HRESULT).self)
            let releaseHr = releaseBuffer(renderClient, numFramesAvailable, 0)
            if loopCount <= 3 && releaseHr != S_OK {
                print("WASAPI: ReleaseBuffer failed: 0x\(String(releaseHr, radix: 16))")
            }
        }
        
        return 0
    }
}

#endif // os(Windows)
