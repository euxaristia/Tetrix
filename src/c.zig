// C library bindings for GLFW, OpenGL, ALSA (Linux), and WASAPI (Windows)
const builtin = @import("builtin");
const c_bindings = if (builtin.target.os.tag == .linux)
    @cImport({
        @cInclude("GLFW/glfw3.h");
        @cInclude("GL/gl.h");
        @cInclude("alsa/asoundlib.h");
    })
else if (builtin.target.os.tag == .windows)
    @cImport({
        @cInclude("GLFW/glfw3.h");
        @cInclude("GL/gl.h");
        @cInclude("windows.h");
        @cInclude("mmdeviceapi.h");
        @cInclude("audioclient.h");
    })
else
    @cImport({
        @cInclude("GLFW/glfw3.h");
        @cInclude("GL/gl.h");
    });

// Re-export all C symbols
pub const GLFWwindow = c_bindings.GLFWwindow;
pub const glfwInit = c_bindings.glfwInit;
pub const glfwTerminate = c_bindings.glfwTerminate;
pub const glfwCreateWindow = c_bindings.glfwCreateWindow;
pub const glfwDestroyWindow = c_bindings.glfwDestroyWindow;
pub const glfwMakeContextCurrent = c_bindings.glfwMakeContextCurrent;
pub const glfwSwapInterval = c_bindings.glfwSwapInterval;
pub const glfwWindowShouldClose = c_bindings.glfwWindowShouldClose;
pub const glfwPollEvents = c_bindings.glfwPollEvents;
pub const glfwSwapBuffers = c_bindings.glfwSwapBuffers;
pub const glfwGetTime = c_bindings.glfwGetTime;
pub const glfwSetKeyCallback = c_bindings.glfwSetKeyCallback;
pub const glfwSetFramebufferSizeCallback = c_bindings.glfwSetFramebufferSizeCallback;
pub const glfwGetKey = c_bindings.glfwGetKey;
pub const glfwJoystickPresent = c_bindings.glfwJoystickPresent;
pub const glfwGetJoystickAxes = c_bindings.glfwGetJoystickAxes;
pub const glfwGetJoystickButtons = c_bindings.glfwGetJoystickButtons;
pub const glfwGetGamepadState = c_bindings.glfwGetGamepadState;
pub const glfwJoystickIsGamepad = c_bindings.glfwJoystickIsGamepad;
pub const glfwGetPrimaryMonitor = c_bindings.glfwGetPrimaryMonitor;
pub const glfwGetVideoMode = c_bindings.glfwGetVideoMode;
pub const glfwSetWindowMonitor = c_bindings.glfwSetWindowMonitor;
pub const glfwGetWindowPos = c_bindings.glfwGetWindowPos;
pub const glfwGetWindowSize = c_bindings.glfwGetWindowSize;

pub const GLFW_TRUE = c_bindings.GLFW_TRUE;
pub const GLFW_PRESS = c_bindings.GLFW_PRESS;
pub const GLFW_JOYSTICK_1 = c_bindings.GLFW_JOYSTICK_1;

// GLFW Gamepad API constants
pub const GLFWgamepadstate = c_bindings.GLFWgamepadstate;
pub const GLFW_GAMEPAD_BUTTON_DPAD_UP = c_bindings.GLFW_GAMEPAD_BUTTON_DPAD_UP;
pub const GLFW_GAMEPAD_BUTTON_DPAD_DOWN = c_bindings.GLFW_GAMEPAD_BUTTON_DPAD_DOWN;
pub const GLFW_GAMEPAD_BUTTON_DPAD_LEFT = c_bindings.GLFW_GAMEPAD_BUTTON_DPAD_LEFT;
pub const GLFW_GAMEPAD_BUTTON_DPAD_RIGHT = c_bindings.GLFW_GAMEPAD_BUTTON_DPAD_RIGHT;
pub const GLFW_GAMEPAD_BUTTON_A = c_bindings.GLFW_GAMEPAD_BUTTON_A;
pub const GLFW_GAMEPAD_BUTTON_B = c_bindings.GLFW_GAMEPAD_BUTTON_B;
pub const GLFW_GAMEPAD_BUTTON_X = c_bindings.GLFW_GAMEPAD_BUTTON_X;
pub const GLFW_GAMEPAD_BUTTON_Y = c_bindings.GLFW_GAMEPAD_BUTTON_Y;
pub const GLFW_GAMEPAD_BUTTON_START = c_bindings.GLFW_GAMEPAD_BUTTON_START;
pub const GLFW_GAMEPAD_BUTTON_BACK = c_bindings.GLFW_GAMEPAD_BUTTON_BACK;
pub const GLFW_GAMEPAD_AXIS_LEFT_X = c_bindings.GLFW_GAMEPAD_AXIS_LEFT_X;
pub const GLFW_GAMEPAD_AXIS_LEFT_Y = c_bindings.GLFW_GAMEPAD_AXIS_LEFT_Y;
pub const GLFW_KEY_UP = c_bindings.GLFW_KEY_UP;
pub const GLFW_KEY_DOWN = c_bindings.GLFW_KEY_DOWN;
pub const GLFW_KEY_LEFT = c_bindings.GLFW_KEY_LEFT;
pub const GLFW_KEY_RIGHT = c_bindings.GLFW_KEY_RIGHT;
pub const GLFW_KEY_W = c_bindings.GLFW_KEY_W;
pub const GLFW_KEY_A = c_bindings.GLFW_KEY_A;
pub const GLFW_KEY_S = c_bindings.GLFW_KEY_S;
pub const GLFW_KEY_D = c_bindings.GLFW_KEY_D;
pub const GLFW_KEY_SPACE = c_bindings.GLFW_KEY_SPACE;
pub const GLFW_KEY_ESCAPE = c_bindings.GLFW_KEY_ESCAPE;
pub const GLFW_KEY_R = c_bindings.GLFW_KEY_R;
pub const GLFW_KEY_M = c_bindings.GLFW_KEY_M;
pub const GLFW_KEY_F11 = c_bindings.GLFW_KEY_F11;

// OpenGL
pub const glClear = c_bindings.glClear;
pub const glClearColor = c_bindings.glClearColor;
pub const glColor4f = c_bindings.glColor4f;
pub const glBegin = c_bindings.glBegin;
pub const glEnd = c_bindings.glEnd;
pub const glVertex2f = c_bindings.glVertex2f;
pub const glEnable = c_bindings.glEnable;
pub const glBlendFunc = c_bindings.glBlendFunc;
pub const glMatrixMode = c_bindings.glMatrixMode;
pub const glLoadIdentity = c_bindings.glLoadIdentity;
pub const glOrtho = c_bindings.glOrtho;
pub const glViewport = c_bindings.glViewport;

pub const GL_COLOR_BUFFER_BIT = c_bindings.GL_COLOR_BUFFER_BIT;
pub const GL_QUADS = c_bindings.GL_QUADS;
pub const GL_LINE_LOOP = c_bindings.GL_LINE_LOOP;
pub const GL_LINES = c_bindings.GL_LINES;
pub const GL_BLEND = c_bindings.GL_BLEND;
pub const GL_SRC_ALPHA = c_bindings.GL_SRC_ALPHA;
pub const GL_ONE_MINUS_SRC_ALPHA = c_bindings.GL_ONE_MINUS_SRC_ALPHA;
pub const GL_PROJECTION = c_bindings.GL_PROJECTION;
pub const GL_MODELVIEW = c_bindings.GL_MODELVIEW;

// ALSA (Linux only) - Windows builds will need audio disabled or Windows audio API implemented
const AlsaPcmT = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_t else *opaque {};
const AlsaHwParamsT = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_t else *opaque {};

pub const snd_pcm_t = AlsaPcmT;
pub const snd_pcm_hw_params_t = AlsaHwParamsT;

fn stub_snd_pcm_open(_: ?*?*AlsaPcmT, _: [*:0]const u8, _: c_int, _: c_int) c_int { return -1; }
fn stub_snd_pcm_close(_: ?*AlsaPcmT) c_int { return 0; }
fn stub_snd_pcm_drain(_: ?*AlsaPcmT) c_int { return 0; }
fn stub_snd_pcm_prepare(_: ?*AlsaPcmT) c_int { return -1; }
fn stub_snd_pcm_writei(_: ?*AlsaPcmT, _: ?*const anyopaque, _: u64) i64 { return -1; }
fn stub_snd_pcm_recover(_: ?*AlsaPcmT, _: c_int, _: c_int) c_int { return -1; }
fn stub_snd_pcm_hw_params_malloc(_: ?*?*AlsaHwParamsT) c_int { return -1; }
fn stub_snd_pcm_hw_params_free(_: ?*AlsaHwParamsT) void {}
fn stub_snd_pcm_hw_params_any(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT) c_int { return -1; }
fn stub_snd_pcm_hw_params_set_access(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: c_int) c_int { return -1; }
fn stub_snd_pcm_hw_params_set_format(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: c_int) c_int { return -1; }
fn stub_snd_pcm_hw_params_set_channels(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: c_uint) c_int { return -1; }
fn stub_snd_pcm_hw_params_set_rate_near(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: ?*c_uint, _: ?*c_int) c_int { return -1; }
fn stub_snd_pcm_hw_params(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT) c_int { return -1; }
fn stub_snd_pcm_hw_params_set_buffer_size_near(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: ?*u64) c_int { return -1; }
fn stub_snd_pcm_hw_params_set_period_size_near(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: ?*u64, _: ?*c_int) c_int { return -1; }

pub const snd_pcm_open = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_open else stub_snd_pcm_open;
pub const snd_pcm_close = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_close else stub_snd_pcm_close;
pub const snd_pcm_drain = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_drain else stub_snd_pcm_drain;
pub const snd_pcm_prepare = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_prepare else stub_snd_pcm_prepare;
pub const snd_pcm_writei = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_writei else stub_snd_pcm_writei;
pub const snd_pcm_recover = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_recover else stub_snd_pcm_recover;
pub const snd_pcm_hw_params_malloc = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_malloc else stub_snd_pcm_hw_params_malloc;
pub const snd_pcm_hw_params_free = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_free else stub_snd_pcm_hw_params_free;
pub const snd_pcm_hw_params_any = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_any else stub_snd_pcm_hw_params_any;
pub const snd_pcm_hw_params_set_access = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_set_access else stub_snd_pcm_hw_params_set_access;
pub const snd_pcm_hw_params_set_format = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_set_format else stub_snd_pcm_hw_params_set_format;
pub const snd_pcm_hw_params_set_channels = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_set_channels else stub_snd_pcm_hw_params_set_channels;
pub const snd_pcm_hw_params_set_rate_near = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_set_rate_near else stub_snd_pcm_hw_params_set_rate_near;
pub const snd_pcm_hw_params = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params else stub_snd_pcm_hw_params;
pub const snd_pcm_hw_params_set_buffer_size_near = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_set_buffer_size_near else stub_snd_pcm_hw_params_set_buffer_size_near;
pub const snd_pcm_hw_params_set_period_size_near = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_hw_params_set_period_size_near else stub_snd_pcm_hw_params_set_period_size_near;

pub const SND_PCM_STREAM_PLAYBACK = if (builtin.target.os.tag == .linux) c_bindings.SND_PCM_STREAM_PLAYBACK else @as(c_int, 0);
pub const SND_PCM_ACCESS_RW_INTERLEAVED = if (builtin.target.os.tag == .linux) c_bindings.SND_PCM_ACCESS_RW_INTERLEAVED else @as(c_int, 0);
pub const SND_PCM_FORMAT_S16_LE = if (builtin.target.os.tag == .linux) c_bindings.SND_PCM_FORMAT_S16_LE else @as(c_int, 0);
pub const SND_PCM_FORMAT_S32_LE = if (builtin.target.os.tag == .linux) c_bindings.SND_PCM_FORMAT_S32_LE else @as(c_int, 0);
pub const SND_PCM_NONBLOCK = if (builtin.target.os.tag == .linux) c_bindings.SND_PCM_NONBLOCK else @as(c_int, 0);
pub const snd_pcm_uframes_t = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_uframes_t else u64;
pub const snd_pcm_sframes_t = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_sframes_t else i64;

// WASAPI (Windows only) - COM interfaces accessed through vtables
// We'll use the Windows headers which define the interfaces properly
pub const IAudioClient = if (builtin.target.os.tag == .windows) c_bindings.IAudioClient else *opaque {};
pub const IAudioRenderClient = if (builtin.target.os.tag == .windows) c_bindings.IAudioRenderClient else *opaque {};
pub const IMMDeviceEnumerator = if (builtin.target.os.tag == .windows) c_bindings.IMMDeviceEnumerator else *opaque {};
pub const IMMDevice = if (builtin.target.os.tag == .windows) c_bindings.IMMDevice else *opaque {};
pub const IUnknown = if (builtin.target.os.tag == .windows) c_bindings.IUnknown else *opaque {};

// WASAPI constants
pub const CLSCTX_ALL = if (builtin.target.os.tag == .windows) c_bindings.CLSCTX_ALL else @as(c_uint, 0);
pub const eRender = if (builtin.target.os.tag == .windows) c_bindings.eRender else @as(c_int, 0);
pub const eConsole = if (builtin.target.os.tag == .windows) c_bindings.eConsole else @as(c_int, 0);
pub const AUDCLNT_SHAREMODE_SHARED = if (builtin.target.os.tag == .windows) c_bindings.AUDCLNT_SHAREMODE_SHARED else @as(c_int, 0);
pub const AUDCLNT_STREAMFLAGS_EVENTCALLBACK = if (builtin.target.os.tag == .windows) c_bindings.AUDCLNT_STREAMFLAGS_EVENTCALLBACK else @as(c_uint, 0);

// WASAPI GUIDs (IIDs and CLSIDs) - these are defined in the Windows headers
pub const IID_IMMDeviceEnumerator = if (builtin.target.os.tag == .windows) &c_bindings.IID_IMMDeviceEnumerator else @as(*const c_bindings.GUID, @ptrCast(&[1]c_bindings.GUID{.{}}));
pub const CLSID_MMDeviceEnumerator = if (builtin.target.os.tag == .windows) &c_bindings.CLSID_MMDeviceEnumerator else @as(*const c_bindings.GUID, @ptrCast(&[1]c_bindings.GUID{.{}}));
pub const IID_IAudioClient = if (builtin.target.os.tag == .windows) &c_bindings.IID_IAudioClient else @as(*const c_bindings.GUID, @ptrCast(&[1]c_bindings.GUID{.{}}));
pub const IID_IAudioRenderClient = if (builtin.target.os.tag == .windows) &c_bindings.IID_IAudioRenderClient else @as(*const c_bindings.GUID, @ptrCast(&[1]c_bindings.GUID{.{}}));

// COM function stubs
fn stub_CoInitializeEx(_: ?*anyopaque, _: c_ulong) c_int { return -1; }
fn stub_CoUninitialize() void {}
fn stub_CoCreateInstance(_: *const c_bindings.GUID, _: ?*anyopaque, _: c_ulong, _: *const c_bindings.GUID, _: *?*anyopaque) c_int { return -1; }

// COM functions
pub const CoInitializeEx = if (builtin.target.os.tag == .windows) c_bindings.CoInitializeEx else stub_CoInitializeEx;
pub const CoUninitialize = if (builtin.target.os.tag == .windows) c_bindings.CoUninitialize else stub_CoUninitialize;
pub const CoCreateInstance = if (builtin.target.os.tag == .windows) c_bindings.CoCreateInstance else stub_CoCreateInstance;

// WAVEFORMATEX structure
pub const WAVEFORMATEX = if (builtin.target.os.tag == .windows) c_bindings.WAVEFORMATEX else struct {
    wFormatTag: c_ushort,
    nChannels: c_ushort,
    nSamplesPerSec: c_ulong,
    nAvgBytesPerSec: c_ulong,
    nBlockAlign: c_ushort,
    wBitsPerSample: c_ushort,
    cbSize: c_ushort,
};

// COM interface vtables - Windows headers define these, but we need to access them in Zig
// COM interfaces have the structure: { lpVtbl: *VTable }
// The vtable contains function pointers for each method
const WasapiVtbls = if (builtin.target.os.tag == .windows) struct {
    // Define vtable structures for COM interfaces
    // These match the Windows SDK definitions
    pub const IMMDeviceEnumeratorVtbl = extern struct {
        QueryInterface: fn (*IMMDeviceEnumerator, *const c_bindings.GUID, *?*anyopaque) callconv(.C) c_int,
        AddRef: fn (*IMMDeviceEnumerator) callconv(.C) c_ulong,
        Release: fn (*IMMDeviceEnumerator) callconv(.C) c_ulong,
        EnumAudioEndpoints: fn (*IMMDeviceEnumerator, c_int, c_int, *?*anyopaque) callconv(.C) c_int,
        GetDefaultAudioEndpoint: fn (*IMMDeviceEnumerator, c_int, c_int, *?*IMMDevice) callconv(.C) c_int,
        GetDevice: fn (*IMMDeviceEnumerator, [*:0]const u16, *?*IMMDevice) callconv(.C) c_int,
        RegisterEndpointNotificationCallback: fn (*IMMDeviceEnumerator, *anyopaque) callconv(.C) c_int,
        UnregisterEndpointNotificationCallback: fn (*IMMDeviceEnumerator, *anyopaque) callconv(.C) c_int,
    };

    pub const IMMDeviceVtbl = extern struct {
        QueryInterface: fn (*IMMDevice, *const c_bindings.GUID, *?*anyopaque) callconv(.C) c_int,
        AddRef: fn (*IMMDevice) callconv(.C) c_ulong,
        Release: fn (*IMMDevice) callconv(.C) c_ulong,
        OpenPropertyStore: fn (*IMMDevice, c_ulong, *?*anyopaque) callconv(.C) c_int,
        GetId: fn (*IMMDevice, *[*:0]u16) callconv(.C) c_int,
        GetState: fn (*IMMDevice, *c_ulong) callconv(.C) c_int,
        Activate: fn (*IMMDevice, *const c_bindings.GUID, c_ulong, ?*c_bindings.PROPVARIANT, *?*anyopaque) callconv(.C) c_int,
    };

    pub const IAudioClientVtbl = extern struct {
        QueryInterface: fn (*IAudioClient, *const c_bindings.GUID, *?*anyopaque) callconv(.C) c_int,
        AddRef: fn (*IAudioClient) callconv(.C) c_ulong,
        Release: fn (*IAudioClient) callconv(.C) c_ulong,
        Initialize: fn (*IAudioClient, c_ulong, c_ulong, c_ulong, c_ulong, *const WAVEFORMATEX, ?*const c_bindings.GUID) callconv(.C) c_int,
        GetBufferSize: fn (*IAudioClient, *c_ulong) callconv(.C) c_int,
        GetStreamLatency: fn (*IAudioClient, *c_ulong) callconv(.C) c_int,
        GetCurrentPadding: fn (*IAudioClient, *c_ulong) callconv(.C) c_int,
        IsFormatSupported: fn (*IAudioClient, c_ulong, *const WAVEFORMATEX, ?*?*WAVEFORMATEX) callconv(.C) c_int,
        GetMixFormat: fn (*IAudioClient, **WAVEFORMATEX) callconv(.C) c_int,
        GetDevicePeriod: fn (*IAudioClient, *c_ulong, *c_ulong) callconv(.C) c_int,
        Start: fn (*IAudioClient) callconv(.C) c_int,
        Stop: fn (*IAudioClient) callconv(.C) c_int,
        Reset: fn (*IAudioClient) callconv(.C) c_int,
        SetEventHandle: fn (*IAudioClient, ?*anyopaque) callconv(.C) c_int,
        GetService: fn (*IAudioClient, *const c_bindings.GUID, *?*anyopaque) callconv(.C) c_int,
    };

    pub const IAudioRenderClientVtbl = extern struct {
        QueryInterface: fn (*IAudioRenderClient, *const c_bindings.GUID, *?*anyopaque) callconv(.C) c_int,
        AddRef: fn (*IAudioRenderClient) callconv(.C) c_ulong,
        Release: fn (*IAudioRenderClient) callconv(.C) c_ulong,
        GetBuffer: fn (*IAudioRenderClient, c_ulong, *[*]u8) callconv(.C) c_int,
        ReleaseBuffer: fn (*IAudioRenderClient, c_ulong, c_ulong) callconv(.C) c_int,
    };

    // COM interface structure - first member is vtable pointer
    const IMMDeviceEnumeratorImpl = extern struct {
        lpVtbl: *IMMDeviceEnumeratorVtbl,
    };
    const IMMDeviceImpl = extern struct {
        lpVtbl: *IMMDeviceVtbl,
    };
    const IAudioClientImpl = extern struct {
        lpVtbl: *IAudioClientVtbl,
    };
    const IAudioRenderClientImpl = extern struct {
        lpVtbl: *IAudioRenderClientVtbl,
    };

    // Helper functions to access vtables and call methods
    pub fn IMMDeviceEnumerator_GetDefaultAudioEndpoint(
        enumerator: *IMMDeviceEnumerator,
        dataFlow: c_int,
        role: c_int,
        ppDevice: *?*IMMDevice,
    ) c_int {
        const impl = @as(*IMMDeviceEnumeratorImpl, @ptrCast(enumerator));
        return impl.lpVtbl.GetDefaultAudioEndpoint(enumerator, dataFlow, role, ppDevice);
    }

    pub fn IMMDevice_Activate(
        device: *IMMDevice,
        iid: *const c_bindings.GUID,
        dwClsCtx: c_ulong,
        pActivationParams: ?*c_bindings.PROPVARIANT,
        ppInterface: *?*anyopaque,
    ) c_int {
        const impl = @as(*IMMDeviceImpl, @ptrCast(device));
        return impl.lpVtbl.Activate(device, iid, dwClsCtx, pActivationParams, ppInterface);
    }

    pub fn IAudioClient_Initialize(
        client: *IAudioClient,
        shareMode: c_ulong,
        streamFlags: c_ulong,
        hnsBufferDuration: c_ulong,
        hnsPeriodicity: c_ulong,
        pFormat: *const WAVEFORMATEX,
        audioSessionGuid: ?*const c_bindings.GUID,
    ) c_int {
        const impl = @as(*IAudioClientImpl, @ptrCast(client));
        return impl.lpVtbl.Initialize(client, shareMode, streamFlags, hnsBufferDuration, hnsPeriodicity, pFormat, audioSessionGuid);
    }

    pub fn IAudioClient_GetBufferSize(
        client: *IAudioClient,
        pNumBufferFrames: *c_ulong,
    ) c_int {
        const impl = @as(*IAudioClientImpl, @ptrCast(client));
        return impl.lpVtbl.GetBufferSize(client, pNumBufferFrames);
    }

    pub fn IAudioClient_GetService(
        client: *IAudioClient,
        riid: *const c_bindings.GUID,
        ppv: *?*anyopaque,
    ) c_int {
        const impl = @as(*IAudioClientImpl, @ptrCast(client));
        return impl.lpVtbl.GetService(client, riid, ppv);
    }

    pub fn IAudioClient_Start(client: *IAudioClient) c_int {
        const impl = @as(*IAudioClientImpl, @ptrCast(client));
        return impl.lpVtbl.Start(client);
    }

    pub fn IAudioClient_Stop(client: *IAudioClient) c_int {
        const impl = @as(*IAudioClientImpl, @ptrCast(client));
        return impl.lpVtbl.Stop(client);
    }

    pub fn IAudioClient_Reset(client: *IAudioClient) c_int {
        const impl = @as(*IAudioClientImpl, @ptrCast(client));
        return impl.lpVtbl.Reset(client);
    }

    pub fn IAudioRenderClient_GetBuffer(
        renderClient: *IAudioRenderClient,
        numFramesRequested: c_ulong,
        ppData: *[*]u8,
    ) c_int {
        const impl = @as(*IAudioRenderClientImpl, @ptrCast(renderClient));
        return impl.lpVtbl.GetBuffer(renderClient, numFramesRequested, ppData);
    }

    pub fn IAudioRenderClient_ReleaseBuffer(
        renderClient: *IAudioRenderClient,
        numFramesWritten: c_ulong,
        dwFlags: c_ulong,
    ) c_int {
        const impl = @as(*IAudioRenderClientImpl, @ptrCast(renderClient));
        return impl.lpVtbl.ReleaseBuffer(renderClient, numFramesWritten, dwFlags);
    }
};

// Export functions at module level
pub const IMMDeviceEnumerator_GetDefaultAudioEndpoint = if (builtin.target.os.tag == .windows) WasapiVtbls.IMMDeviceEnumerator_GetDefaultAudioEndpoint else struct {
    fn call(_: *IMMDeviceEnumerator, _: c_int, _: c_int, _: *?*IMMDevice) c_int { return -1; }
}.call;
pub const IMMDevice_Activate = if (builtin.target.os.tag == .windows) WasapiVtbls.IMMDevice_Activate else struct {
    fn call(_: *IMMDevice, _: *const c_bindings.GUID, _: c_ulong, _: ?*c_bindings.PROPVARIANT, _: *?*anyopaque) c_int { return -1; }
}.call;
pub const IAudioClient_Initialize = if (builtin.target.os.tag == .windows) WasapiVtbls.IAudioClient_Initialize else struct {
    fn call(_: *IAudioClient, _: c_ulong, _: c_ulong, _: c_ulong, _: c_ulong, _: *const WAVEFORMATEX, _: ?*const c_bindings.GUID) c_int { return -1; }
}.call;
pub const IAudioClient_GetBufferSize = if (builtin.target.os.tag == .windows) WasapiVtbls.IAudioClient_GetBufferSize else struct {
    fn call(_: *IAudioClient, _: *c_ulong) c_int { return -1; }
}.call;
pub const IAudioClient_GetService = if (builtin.target.os.tag == .windows) WasapiVtbls.IAudioClient_GetService else struct {
    fn call(_: *IAudioClient, _: *const c_bindings.GUID, _: *?*anyopaque) c_int { return -1; }
}.call;
pub const IAudioClient_Start = if (builtin.target.os.tag == .windows) WasapiVtbls.IAudioClient_Start else struct {
    fn call(_: *IAudioClient) c_int { return -1; }
}.call;
pub const IAudioClient_Stop = if (builtin.target.os.tag == .windows) WasapiVtbls.IAudioClient_Stop else struct {
    fn call(_: *IAudioClient) c_int { return -1; }
}.call;
pub const IAudioClient_Reset = if (builtin.target.os.tag == .windows) WasapiVtbls.IAudioClient_Reset else struct {
    fn call(_: *IAudioClient) c_int { return -1; }
}.call;
pub const IAudioRenderClient_GetBuffer = if (builtin.target.os.tag == .windows) WasapiVtbls.IAudioRenderClient_GetBuffer else struct {
    fn call(_: *IAudioRenderClient, _: c_ulong, _: *[*]u8) c_int { return -1; }
}.call;
pub const IAudioRenderClient_ReleaseBuffer = if (builtin.target.os.tag == .windows) WasapiVtbls.IAudioRenderClient_ReleaseBuffer else struct {
    fn call(_: *IAudioRenderClient, _: c_ulong, _: c_ulong) c_int { return -1; }
}.call;
