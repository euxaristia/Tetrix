#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#define COBJMACROS
#define INITGUID
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
// Define GUIDs manually to avoid linker issues
static const GUID CLSID_MMDeviceEnumerator_Value = { 0xBCDE0395, 0xE52F, 0x467C, { 0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E } };
static const GUID IID_IMMDeviceEnumerator_Value = { 0xA95664D2, 0x9614, 0x4F35, { 0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6 } };
static const GUID IID_IMMDevice_Value = { 0xD666063F, 0x1587, 0x4E43, { 0x81, 0xF1, 0xB9, 0x48, 0xE8, 0x07, 0x03, 0x30 } };
static const GUID IID_IAudioClient_Value = { 0x1CB9AD4C, 0xDBFA, 0x4C32, { 0xB1, 0x78, 0xC2, 0xF5, 0x68, 0xA7, 0x03, 0xB2 } };
static const GUID IID_IAudioRenderClient_Value = { 0xF294ACFC, 0x3146, 0x4483, { 0xA7, 0xBF, 0xAD, 0xDC, 0xA7, 0xC2, 0x60, 0xE2 } };

#define CLSID_MMDeviceEnumerator CLSID_MMDeviceEnumerator_Value
#define IID_IMMDeviceEnumerator IID_IMMDeviceEnumerator_Value
#define IID_IMMDevice IID_IMMDevice_Value
#define IID_IAudioClient IID_IAudioClient_Value
#define IID_IAudioRenderClient IID_IAudioRenderClient_Value

#include <mmdeviceapi.h>
#include <audioclient.h>
#include <avrt.h>

// WASAPI audio context
typedef struct {
    IMMDeviceEnumerator* enumerator;
    IMMDevice* device;
    IAudioClient* audioClient;
    IAudioRenderClient* renderClient;
    HANDLE thread;
    HANDLE stopEvent;
    HANDLE bufferReadyEvent;
    UINT32 bufferFrameCount;
    UINT32 sampleRate;
    UINT16 channels;
    int isActive;
    int comInitialized;  // Track if we initialized COM
    void* userData;
    int32_t (*dataProvider)(void* userData, int16_t* buffer, int32_t samples);
} WASAPIContext;

// Forward declaration
static DWORD WINAPI AudioThreadProc(LPVOID lpParam);

void* wasapi_audio_create(int sample_rate, int channels) {
    printf("WASAPI: Creating audio stream (rate=%d, channels=%d)\n", sample_rate, channels);
    HRESULT hr;
    WASAPIContext* ctx = (WASAPIContext*)calloc(1, sizeof(WASAPIContext));
    if (!ctx) {
        printf("WASAPI: Failed to allocate context\n");
        return NULL;
    }
    
    ctx->sampleRate = (UINT32)sample_rate;
    ctx->channels = (UINT16)channels;
    ctx->stopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    ctx->bufferReadyEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
    
    if (!ctx->stopEvent || !ctx->bufferReadyEvent) {
        free(ctx);
        return NULL;
    }
    
    // Initialize COM
    hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
    ctx->comInitialized = (hr == S_OK) ? 1 : 0;  // Track if we initialized it
    if (FAILED(hr) && hr != RPC_E_CHANGED_MODE && hr != S_FALSE) {
        // S_FALSE means COM was already initialized, which is fine
        printf("WASAPI: CoInitializeEx failed: 0x%08X\n", hr);
        CloseHandle(ctx->stopEvent);
        CloseHandle(ctx->bufferReadyEvent);
        free(ctx);
        return NULL;
    }
    
    // Get device enumerator
    hr = CoCreateInstance(
        &CLSID_MMDeviceEnumerator,
        NULL,
        CLSCTX_ALL,
        &IID_IMMDeviceEnumerator,
        (void**)&ctx->enumerator
    );
    
    if (FAILED(hr)) {
        if (ctx->comInitialized) CoUninitialize();
        CloseHandle(ctx->stopEvent);
        CloseHandle(ctx->bufferReadyEvent);
        free(ctx);
        return NULL;
    }
    
    // Get default audio endpoint
    hr = IMMDeviceEnumerator_GetDefaultAudioEndpoint(
        ctx->enumerator,
        eRender,
        eConsole,
        &ctx->device
    );
    
    if (FAILED(hr)) {
        printf("WASAPI: GetDefaultAudioEndpoint failed: 0x%08X\n", hr);
        IMMDeviceEnumerator_Release(ctx->enumerator);
        if (ctx->comInitialized) CoUninitialize();
        CloseHandle(ctx->stopEvent);
        CloseHandle(ctx->bufferReadyEvent);
        free(ctx);
        return NULL;
    }
    
    // Activate audio client
    hr = IMMDevice_Activate(
        ctx->device,
        &IID_IAudioClient,
        CLSCTX_ALL,
        NULL,
        (void**)&ctx->audioClient
    );
    
    if (FAILED(hr)) {
        IMMDevice_Release(ctx->device);
        IMMDeviceEnumerator_Release(ctx->enumerator);
        if (ctx->comInitialized) CoUninitialize();
        CloseHandle(ctx->stopEvent);
        CloseHandle(ctx->bufferReadyEvent);
        free(ctx);
        return NULL;
    }
    
    // Get device's mix format - it might be WAVEFORMATEXTENSIBLE
    WAVEFORMATEX* pwfx = NULL;
    hr = IAudioClient_GetMixFormat(ctx->audioClient, &pwfx);
    if (FAILED(hr)) {
        printf("WASAPI: GetMixFormat failed: 0x%08X\n", hr);
        IAudioClient_Release(ctx->audioClient);
        IMMDevice_Release(ctx->device);
        IMMDeviceEnumerator_Release(ctx->enumerator);
        if (ctx->comInitialized) CoUninitialize();
        CloseHandle(ctx->stopEvent);
        CloseHandle(ctx->bufferReadyEvent);
        free(ctx);
        return NULL;
    }
    
    // Store format info
    ctx->channels = pwfx->nChannels;
    ctx->sampleRate = pwfx->nSamplesPerSec;
    
    // Initialize audio client with the format pointer directly
    // Windows will use the format as-is (including WAVEFORMATEXTENSIBLE if that's what it is)
    hr = IAudioClient_Initialize(
        ctx->audioClient,
        AUDCLNT_SHAREMODE_SHARED,
        0,  // No special flags
        0,  // Use device default buffer size in shared mode
        0,
        pwfx,  // Use the format pointer directly
        NULL   // Don't need actual format back
    );
    
    // Free the format after Initialize (it doesn't take ownership)
    CoTaskMemFree(pwfx);
    pwfx = NULL;
    
    if (FAILED(hr)) {
        printf("WASAPI: IAudioClient_Initialize failed: 0x%08X\n", hr);
        IAudioClient_Release(ctx->audioClient);
        IMMDevice_Release(ctx->device);
        IMMDeviceEnumerator_Release(ctx->enumerator);
        if (ctx->comInitialized) CoUninitialize();
        CloseHandle(ctx->stopEvent);
        CloseHandle(ctx->bufferReadyEvent);
        free(ctx);
        return NULL;
    }
    
    // Try to set event handle for event-driven audio
    // This may fail on some systems, but we can work without it
    IAudioClient_SetEventHandle(ctx->audioClient, ctx->bufferReadyEvent);
    
    // Get buffer size
    hr = IAudioClient_GetBufferSize(ctx->audioClient, &ctx->bufferFrameCount);
    if (FAILED(hr)) {
        IAudioClient_Release(ctx->audioClient);
        IMMDevice_Release(ctx->device);
        IMMDeviceEnumerator_Release(ctx->enumerator);
        if (ctx->comInitialized) CoUninitialize();
        CloseHandle(ctx->stopEvent);
        CloseHandle(ctx->bufferReadyEvent);
        free(ctx);
        return NULL;
    }
    
    // Get render client
    hr = IAudioClient_GetService(
        ctx->audioClient,
        &IID_IAudioRenderClient,
        (void**)&ctx->renderClient
    );
    
    if (FAILED(hr)) {
        IAudioClient_Release(ctx->audioClient);
        IMMDevice_Release(ctx->device);
        IMMDeviceEnumerator_Release(ctx->enumerator);
        if (ctx->comInitialized) CoUninitialize();
        CloseHandle(ctx->stopEvent);
        CloseHandle(ctx->bufferReadyEvent);
        free(ctx);
        return NULL;
    }
    
    return ctx;
}

int wasapi_audio_write(void* context, const void* data, size_t bytes) {
    // Not used - audio is written in the thread
    return 1;
}

void wasapi_audio_destroy(void* context) {
    WASAPIContext* ctx = (WASAPIContext*)context;
    if (!ctx) return;
    
    // Stop the audio thread
    ctx->isActive = 0;
    if (ctx->stopEvent) {
        SetEvent(ctx->stopEvent);
    }
    
    // Wait for thread to finish
    if (ctx->thread) {
        WaitForSingleObject(ctx->thread, INFINITE);
        CloseHandle(ctx->thread);
    }
    
    // Stop audio client
    if (ctx->audioClient) {
        IAudioClient_Stop(ctx->audioClient);
        IAudioClient_Release(ctx->audioClient);
    }
    
    // Release interfaces
    if (ctx->renderClient) {
        IAudioRenderClient_Release(ctx->renderClient);
    }
    if (ctx->device) {
        IMMDevice_Release(ctx->device);
    }
    if (ctx->enumerator) {
        IMMDeviceEnumerator_Release(ctx->enumerator);
    }
    
    // Cleanup
    if (ctx->stopEvent) CloseHandle(ctx->stopEvent);
    if (ctx->bufferReadyEvent) CloseHandle(ctx->bufferReadyEvent);
    
    // Only uninitialize COM if we initialized it
    if (ctx->comInitialized) {
        CoUninitialize();
    }
    free(ctx);
}

int wasapi_audio_start(void* context) {
    WASAPIContext* ctx = (WASAPIContext*)context;
    if (!ctx) return 0;
    
    ctx->isActive = 1;
    
    // Start audio client
    HRESULT hr = IAudioClient_Start(ctx->audioClient);
    if (FAILED(hr)) {
        ctx->isActive = 0;
        return 0;
    }
    
    // Create audio thread
    ResetEvent(ctx->stopEvent);
    ctx->thread = CreateThread(NULL, 0, AudioThreadProc, ctx, 0, NULL);
    if (!ctx->thread) {
        IAudioClient_Stop(ctx->audioClient);
        ctx->isActive = 0;
        return 0;
    }
    
    return 1;
}

int wasapi_audio_set_data_provider(void* context, void* userData, int32_t (*dataProvider)(void* userData, int16_t* buffer, int32_t samples)) {
    WASAPIContext* ctx = (WASAPIContext*)context;
    if (!ctx) return 0;
    ctx->userData = userData;
    ctx->dataProvider = dataProvider;
    return 1;
}

void wasapi_audio_stop(void* context) {
    WASAPIContext* ctx = (WASAPIContext*)context;
    if (!ctx) return;
    
    ctx->isActive = 0;
    if (ctx->stopEvent) {
        SetEvent(ctx->stopEvent);
    }
    
    if (ctx->audioClient) {
        IAudioClient_Stop(ctx->audioClient);
    }
}

// Audio thread procedure
static DWORD WINAPI AudioThreadProc(LPVOID lpParam) {
    WASAPIContext* ctx = (WASAPIContext*)lpParam;
    HANDLE events[] = { ctx->stopEvent, ctx->bufferReadyEvent };
    
    // Set thread priority for low-latency audio
    AvSetMmThreadCharacteristics("Pro Audio", NULL);
    
    BYTE* pData;
    UINT32 numFramesAvailable;
    UINT32 numFramesPadding;
    HRESULT hr;
    
    while (ctx->isActive) {
        // Wait for buffer ready event or stop event
        // If event handle wasn't set, we'll poll instead
        DWORD waitResult = WaitForMultipleObjects(2, events, FALSE, 10); // 10ms timeout for polling
        if (waitResult == WAIT_OBJECT_0) {
            // Stop event
            break;
        }
        
        // Get padding (this also works for polling mode)
        hr = IAudioClient_GetCurrentPadding(ctx->audioClient, &numFramesPadding);
        if (FAILED(hr)) {
            Sleep(10); // Wait a bit before retrying
            continue;
        }
        
        numFramesAvailable = ctx->bufferFrameCount - numFramesPadding;
        if (numFramesAvailable == 0) {
            // No space available, wait a bit
            Sleep(1);
            continue;
        }
        
        // Get buffer
        hr = IAudioRenderClient_GetBuffer(ctx->renderClient, numFramesAvailable, &pData);
        if (FAILED(hr)) continue;
        
        // Generate audio data
        if (ctx->dataProvider) {
            int16_t* buffer = (int16_t*)pData;
            int32_t samplesNeeded = (int32_t)(numFramesAvailable * ctx->channels);
            int32_t samplesGenerated = ctx->dataProvider(ctx->userData, buffer, samplesNeeded);
            
            // If not enough samples, fill with zeros
            if (samplesGenerated < samplesNeeded) {
                memset(buffer + samplesGenerated, 0, (samplesNeeded - samplesGenerated) * sizeof(int16_t));
            }
        } else {
            // Fill with silence
            memset(pData, 0, numFramesAvailable * ctx->channels * sizeof(int16_t));
        }
        
        // Release buffer
        hr = IAudioRenderClient_ReleaseBuffer(ctx->renderClient, numFramesAvailable, 0);
    }
    
    AvRevertMmThreadCharacteristics(NULL);
    return 0;
}

#endif // _WIN32
