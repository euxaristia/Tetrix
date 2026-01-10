// C library bindings for GLFW, OpenGL, and ALSA
const c_bindings = @cImport({
    @cInclude("GLFW/glfw3.h");
    @cInclude("GL/gl.h");
    @cInclude("alsa/asoundlib.h");
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
pub const glfwGetPrimaryMonitor = c_bindings.glfwGetPrimaryMonitor;
pub const glfwGetVideoMode = c_bindings.glfwGetVideoMode;
pub const glfwSetWindowMonitor = c_bindings.glfwSetWindowMonitor;
pub const glfwGetWindowPos = c_bindings.glfwGetWindowPos;
pub const glfwGetWindowSize = c_bindings.glfwGetWindowSize;

pub const GLFW_TRUE = c_bindings.GLFW_TRUE;
pub const GLFW_PRESS = c_bindings.GLFW_PRESS;
pub const GLFW_JOYSTICK_1 = c_bindings.GLFW_JOYSTICK_1;
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

// ALSA
pub const snd_pcm_t = c_bindings.snd_pcm_t;
pub const snd_pcm_hw_params_t = c_bindings.snd_pcm_hw_params_t;
pub const snd_pcm_open = c_bindings.snd_pcm_open;
pub const snd_pcm_close = c_bindings.snd_pcm_close;
pub const snd_pcm_drain = c_bindings.snd_pcm_drain;
pub const snd_pcm_prepare = c_bindings.snd_pcm_prepare;
pub const snd_pcm_writei = c_bindings.snd_pcm_writei;
pub const snd_pcm_recover = c_bindings.snd_pcm_recover;
pub const snd_pcm_hw_params_malloc = c_bindings.snd_pcm_hw_params_malloc;
pub const snd_pcm_hw_params_free = c_bindings.snd_pcm_hw_params_free;
pub const snd_pcm_hw_params_any = c_bindings.snd_pcm_hw_params_any;
pub const snd_pcm_hw_params_set_access = c_bindings.snd_pcm_hw_params_set_access;
pub const snd_pcm_hw_params_set_format = c_bindings.snd_pcm_hw_params_set_format;
pub const snd_pcm_hw_params_set_channels = c_bindings.snd_pcm_hw_params_set_channels;
pub const snd_pcm_hw_params_set_rate_near = c_bindings.snd_pcm_hw_params_set_rate_near;
pub const snd_pcm_hw_params = c_bindings.snd_pcm_hw_params;

pub const SND_PCM_STREAM_PLAYBACK = c_bindings.SND_PCM_STREAM_PLAYBACK;
pub const SND_PCM_ACCESS_RW_INTERLEAVED = c_bindings.SND_PCM_ACCESS_RW_INTERLEAVED;
pub const SND_PCM_FORMAT_S16_LE = c_bindings.SND_PCM_FORMAT_S16_LE;
pub const SND_PCM_NONBLOCK = c_bindings.SND_PCM_NONBLOCK;
pub const snd_pcm_uframes_t = c_bindings.snd_pcm_uframes_t;
pub const snd_pcm_hw_params_set_buffer_size_near = c_bindings.snd_pcm_hw_params_set_buffer_size_near;
pub const snd_pcm_hw_params_set_period_size_near = c_bindings.snd_pcm_hw_params_set_period_size_near;
