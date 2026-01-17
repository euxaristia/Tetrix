// C library bindings for GLFW, OpenGL, ALSA (Linux), and waveOut (Windows)
const builtin = @import("builtin");
// Note: When cross-compiling, builtin.target.os.tag refers to the TARGET, not host
// So this will correctly include Windows headers when targeting Windows
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
        @cInclude("mmsystem.h");
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

fn stub_snd_pcm_open(_: ?*?*AlsaPcmT, _: [*:0]const u8, _: c_int, _: c_int) c_int {
    return -1;
}
fn stub_snd_pcm_close(_: ?*AlsaPcmT) c_int {
    return 0;
}
fn stub_snd_pcm_drain(_: ?*AlsaPcmT) c_int {
    return 0;
}
fn stub_snd_pcm_drop(_: ?*AlsaPcmT) c_int {
    return 0;
}
fn stub_snd_pcm_prepare(_: ?*AlsaPcmT) c_int {
    return -1;
}
fn stub_snd_pcm_writei(_: ?*AlsaPcmT, _: ?*const anyopaque, _: u64) i64 {
    return -1;
}
fn stub_snd_pcm_recover(_: ?*AlsaPcmT, _: c_int, _: c_int) c_int {
    return -1;
}
fn stub_snd_pcm_hw_params_malloc(_: ?*?*AlsaHwParamsT) c_int {
    return -1;
}
fn stub_snd_pcm_hw_params_free(_: ?*AlsaHwParamsT) void {}
fn stub_snd_pcm_hw_params_any(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT) c_int {
    return -1;
}
fn stub_snd_pcm_hw_params_set_access(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: c_int) c_int {
    return -1;
}
fn stub_snd_pcm_hw_params_set_format(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: c_int) c_int {
    return -1;
}
fn stub_snd_pcm_hw_params_set_channels(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: c_uint) c_int {
    return -1;
}
fn stub_snd_pcm_hw_params_set_rate_near(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: ?*c_uint, _: ?*c_int) c_int {
    return -1;
}
fn stub_snd_pcm_hw_params(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT) c_int {
    return -1;
}
fn stub_snd_pcm_hw_params_set_buffer_size_near(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: ?*u64) c_int {
    return -1;
}
fn stub_snd_pcm_hw_params_set_period_size_near(_: ?*AlsaPcmT, _: ?*AlsaHwParamsT, _: ?*u64, _: ?*c_int) c_int {
    return -1;
}

pub const snd_pcm_open = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_open else stub_snd_pcm_open;
pub const snd_pcm_close = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_close else stub_snd_pcm_close;
pub const snd_pcm_drain = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_drain else stub_snd_pcm_drain;
pub const snd_pcm_drop = if (builtin.target.os.tag == .linux) c_bindings.snd_pcm_drop else stub_snd_pcm_drop;
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

// Windows Multimedia API (waveOut) - simpler than WASAPI, no COM/GUIDs needed
// This is the old Windows audio API, much more primitive but works for cross-compilation
pub const HWAVEOUT = if (builtin.target.os.tag == .windows) c_bindings.HWAVEOUT else *opaque {};
pub const WAVEFORMATEX = if (builtin.target.os.tag == .windows) c_bindings.WAVEFORMATEX else struct {
    wFormatTag: c_ushort,
    nChannels: c_ushort,
    nSamplesPerSec: c_ulong,
    nAvgBytesPerSec: c_ulong,
    nBlockAlign: c_ushort,
    wBitsPerSample: c_ushort,
    cbSize: c_ushort,
};

pub const WAVE_MAPPER = if (builtin.target.os.tag == .windows) c_bindings.WAVE_MAPPER else @as(c_uint, 0);
pub const WAVE_FORMAT_PCM = if (builtin.target.os.tag == .windows) c_bindings.WAVE_FORMAT_PCM else @as(c_ushort, 1);
pub const CALLBACK_NULL = if (builtin.target.os.tag == .windows) c_bindings.CALLBACK_NULL else @as(c_ulong, 0);

// waveOut function stubs for non-Windows
fn stub_waveOutOpen(_: *HWAVEOUT, _: c_uint, _: *const WAVEFORMATEX, _: c_ulong, _: c_ulong, _: c_ulong) c_int {
    return -1;
}
fn stub_waveOutClose(_: HWAVEOUT) c_int {
    return -1;
}
fn stub_waveOutPrepareHeader(_: HWAVEOUT, _: *anyopaque, _: c_uint) c_int {
    return -1;
}
fn stub_waveOutUnprepareHeader(_: HWAVEOUT, _: *anyopaque, _: c_uint) c_int {
    return -1;
}
fn stub_waveOutWrite(_: HWAVEOUT, _: *anyopaque, _: c_uint) c_int {
    return -1;
}
fn stub_waveOutReset(_: HWAVEOUT) c_int {
    return -1;
}

// waveOut functions
pub const waveOutOpen = if (builtin.target.os.tag == .windows) c_bindings.waveOutOpen else stub_waveOutOpen;
pub const waveOutClose = if (builtin.target.os.tag == .windows) c_bindings.waveOutClose else stub_waveOutClose;
pub const waveOutPrepareHeader = if (builtin.target.os.tag == .windows) c_bindings.waveOutPrepareHeader else stub_waveOutPrepareHeader;
pub const waveOutUnprepareHeader = if (builtin.target.os.tag == .windows) c_bindings.waveOutUnprepareHeader else stub_waveOutUnprepareHeader;
pub const waveOutWrite = if (builtin.target.os.tag == .windows) c_bindings.waveOutWrite else stub_waveOutWrite;
pub const waveOutReset = if (builtin.target.os.tag == .windows) c_bindings.waveOutReset else stub_waveOutReset;

// WAVEHDR structure
pub const WAVEHDR = if (builtin.target.os.tag == .windows) c_bindings.WAVEHDR else extern struct {
    lpData: [*]u8,
    dwBufferLength: c_ulong,
    dwBytesRecorded: c_ulong,
    dwUser: c_ulong,
    dwFlags: c_ulong,
    dwLoops: c_ulong,
    lpNext: ?*anyopaque,
    reserved: c_ulong,
};

pub const WHDR_DONE = if (builtin.target.os.tag == .windows) c_bindings.WHDR_DONE else @as(c_ulong, 1);
pub const WHDR_PREPARED = if (builtin.target.os.tag == .windows) c_bindings.WHDR_PREPARED else @as(c_ulong, 2);
pub const WHDR_INQUEUE = if (builtin.target.os.tag == .windows) c_bindings.WHDR_INQUEUE else @as(c_ulong, 4);
