--------------------------------------------------------------------------
-- GLFW - An OpenGL library
-- API version: 3.0
-- WWW:         http://www.glfw.org/
--------------------------------------------------------------------------
-- Copyright (c) 2002-2006 Marcus Geelnard
-- Copyright (c) 2006-2010 Camilla Berglund <elmindreda@elmindreda.org>
-- Copyright (c) 2010-2011 Dimiter "malkia" Stanev <malkia@gmail.com>
--
-- This software is provided 'as-is', without any express or implied
-- warranty. In no event will the authors be held liable for any damages
-- arising from the use of this software.
--
-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it
-- freely, subject to the following restrictions:
--
-- 1. The origin of this software must not be misrepresented; you must not
--    claim that you wrote the original software. If you use this software
--    in a product, an acknowledgment in the product documentation would
--    be appreciated but is not required.
--
-- 2. Altered source versions must be plainly marked as such, and must not
--    be misrepresented as being the original software.
--
-- 3. This notice may not be removed or altered from any source
--    distribution.
--------------------------------------------------------------------------

local ffi = require( "ffi" )
ffi.cdef[[
enum {
   GLFW_VERSION_MAJOR         =  3,
   GLFW_VERSION_MINOR         =  0,
   GLFW_VERSION_REVISION      =  0,
   
   // Key and button state/action definitions 
   GLFW_RELEASE               =  0,
   GLFW_PRESS                 =  1,

   // Keyboard raw key codes.
   // These key codes are inspired by the USB HID Usage Tables v1.12 (p. 53-60),
   // but re-arranged to map to 7-bit ASCII for printable keys (function keys are
   // put in the 256+ range).
   // The naming of the key codes follow these rules:
   //  - The US keyboard layout is used.
   //  - Names of printable alpha-numeric characters are used (e.g. "A", "R",
   //    "3", etc).
   //  - For non-alphanumeric characters, Unicode:ish names are used (e.g.
   //    "COMMA", "LEFT_SQUARE_BRACKET", etc). Note that some names do not
   //    correspond to the Unicode standard (usually for brevity).
   //  - Keys that lack a clear US mapping are named "WORLD_x".
   //  - For non-printable keys, custom names are used (e.g. "F4",
   //    "BACKSPACE", etc).
   GLFW_KEY_SPACE             = 32,
   GLFW_KEY_APOSTROPHE        = 39, 
   GLFW_KEY_COMMA             = 44, 
   GLFW_KEY_MINUS             = 45, 
   GLFW_KEY_PERIOD            = 46, 
   GLFW_KEY_SLASH             = 47, 
   GLFW_KEY_0                 = 48,
   GLFW_KEY_1                 = 49,
   GLFW_KEY_2                 = 50,
   GLFW_KEY_3                 = 51,
   GLFW_KEY_4                 = 52,
   GLFW_KEY_5                 = 53,
   GLFW_KEY_6                 = 54,
   GLFW_KEY_7                 = 55,
   GLFW_KEY_8                 = 56,
   GLFW_KEY_9                 = 57,
   GLFW_KEY_SEMICOLON         = 59, 
   GLFW_KEY_EQUAL             = 61, 
   GLFW_KEY_A                 = 65,
   GLFW_KEY_B                 = 66,
   GLFW_KEY_C                 = 67,
   GLFW_KEY_D                 = 68,
   GLFW_KEY_E                 = 69,
   GLFW_KEY_F                 = 70,
   GLFW_KEY_G                 = 71,
   GLFW_KEY_H                 = 72,
   GLFW_KEY_I                 = 73,
   GLFW_KEY_J                 = 74,
   GLFW_KEY_K                 = 75,
   GLFW_KEY_L                 = 76,
   GLFW_KEY_M                 = 77,
   GLFW_KEY_N                 = 78,
   GLFW_KEY_O                 = 79,
   GLFW_KEY_P                 = 80,
   GLFW_KEY_Q                 = 81,
   GLFW_KEY_R                 = 82,
   GLFW_KEY_S                 = 83,
   GLFW_KEY_T                 = 84,
   GLFW_KEY_U                 = 85,
   GLFW_KEY_V                 = 86,
   GLFW_KEY_W                 = 87,
   GLFW_KEY_X                 = 88,
   GLFW_KEY_Y                 = 89,
   GLFW_KEY_Z                 = 90,
   GLFW_KEY_LEFT_BRACKET      = 91, 
   GLFW_KEY_BACKSLASH         = 92,
   GLFW_KEY_RIGHT_BRACKET     = 93, 
   GLFW_KEY_GRAVE_ACCENT      = 96,
   GLFW_KEY_WORLD_1           = 161,
   GLFW_KEY_WORLD_2           = 162,
   GLFW_KEY_ESCAPE            = 256,
   GLFW_KEY_ENTER             = 257,
   GLFW_KEY_TAB               = 258,
   GLFW_KEY_BACKSPACE         = 259,
   GLFW_KEY_INSERT            = 260,
   GLFW_KEY_DELETE            = 261,
   GLFW_KEY_RIGHT             = 262,
   GLFW_KEY_LEFT              = 263,
   GLFW_KEY_DOWN              = 264,
   GLFW_KEY_UP                = 265,
   GLFW_KEY_PAGE_UP           = 266,
   GLFW_KEY_PAGE_DOWN         = 267,
   GLFW_KEY_HOME              = 268,
   GLFW_KEY_END               = 269,
   GLFW_KEY_CAPS_LOCK         = 280,
   GLFW_KEY_SCROLL_LOCK       = 281,
   GLFW_KEY_NUM_LOCK          = 282,
   GLFW_KEY_PRINT_SCREEN      = 283,
   GLFW_KEY_PAUSE             = 284,
   GLFW_KEY_F1                = 290,
   GLFW_KEY_F2                = 291,
   GLFW_KEY_F3                = 292,
   GLFW_KEY_F4                = 293,
   GLFW_KEY_F5                = 294,
   GLFW_KEY_F6                = 295,
   GLFW_KEY_F7                = 296,
   GLFW_KEY_F8                = 297,
   GLFW_KEY_F9                = 298,
   GLFW_KEY_F10               = 299,
   GLFW_KEY_F11               = 300,
   GLFW_KEY_F12               = 301,
   GLFW_KEY_F13               = 302,
   GLFW_KEY_F14               = 303,
   GLFW_KEY_F15               = 304,
   GLFW_KEY_F16               = 305,
   GLFW_KEY_F17               = 306,
   GLFW_KEY_F18               = 307,
   GLFW_KEY_F19               = 308,
   GLFW_KEY_F20               = 309,
   GLFW_KEY_F21               = 310,
   GLFW_KEY_F22               = 311,
   GLFW_KEY_F23               = 312,
   GLFW_KEY_F24               = 313,
   GLFW_KEY_F25               = 314,
   GLFW_KEY_KP_0              = 320,
   GLFW_KEY_KP_1              = 321,
   GLFW_KEY_KP_2              = 322,
   GLFW_KEY_KP_3              = 323,
   GLFW_KEY_KP_4              = 324,
   GLFW_KEY_KP_5              = 325,
   GLFW_KEY_KP_6              = 326,
   GLFW_KEY_KP_7              = 327,
   GLFW_KEY_KP_8              = 328,
   GLFW_KEY_KP_9              = 329,
   GLFW_KEY_KP_DECIMAL        = 330,
   GLFW_KEY_KP_DIVIDE         = 331,
   GLFW_KEY_KP_MULTIPLY       = 332,
   GLFW_KEY_KP_SUBTRACT       = 333,
   GLFW_KEY_KP_ADD            = 334,
   GLFW_KEY_KP_ENTER          = 335,
   GLFW_KEY_KP_EQUAL          = 336,
   GLFW_KEY_LEFT_SHIFT        = 340,
   GLFW_KEY_LEFT_CONTROL      = 341,
   GLFW_KEY_LEFT_ALT          = 342,
   GLFW_KEY_LEFT_SUPER        = 343,
   GLFW_KEY_RIGHT_SHIFT       = 344,
   GLFW_KEY_RIGHT_CONTROL     = 345,
   GLFW_KEY_RIGHT_ALT         = 346,
   GLFW_KEY_RIGHT_SUPER       = 347,
   GLFW_KEY_MENU              = 348,
   GLFW_KEY_LAST              = GLFW_KEY_MENU,
   GLFW_MOUSE_BUTTON_1        = 0,
   GLFW_MOUSE_BUTTON_2        = 1,
   GLFW_MOUSE_BUTTON_3        = 2,
   GLFW_MOUSE_BUTTON_4        = 3,
   GLFW_MOUSE_BUTTON_5        = 4,
   GLFW_MOUSE_BUTTON_6        = 5,
   GLFW_MOUSE_BUTTON_7        = 6,
   GLFW_MOUSE_BUTTON_8        = 7,
   GLFW_MOUSE_BUTTON_LAST     = GLFW_MOUSE_BUTTON_8,
   GLFW_MOUSE_BUTTON_LEFT     = GLFW_MOUSE_BUTTON_1,
   GLFW_MOUSE_BUTTON_RIGHT    = GLFW_MOUSE_BUTTON_2,
   GLFW_MOUSE_BUTTON_MIDDLE   = GLFW_MOUSE_BUTTON_3,
   GLFW_JOYSTICK_1            = 0,
   GLFW_JOYSTICK_2            = 1,
   GLFW_JOYSTICK_3            = 2,
   GLFW_JOYSTICK_4            = 3,
   GLFW_JOYSTICK_5            = 4,
   GLFW_JOYSTICK_6            = 5,
   GLFW_JOYSTICK_7            = 6,
   GLFW_JOYSTICK_8            = 7,
   GLFW_JOYSTICK_9            = 8,
   GLFW_JOYSTICK_10           = 9,
   GLFW_JOYSTICK_11           = 10,
   GLFW_JOYSTICK_12           = 11,
   GLFW_JOYSTICK_13           = 12,
   GLFW_JOYSTICK_14           = 13,
   GLFW_JOYSTICK_15           = 14,
   GLFW_JOYSTICK_16           = 15,
   GLFW_JOYSTICK_LAST         = GLFW_JOYSTICK_16,

   GLFW_WINDOWED              = 0x00010001,
   GLFW_FULLSCREEN            = 0x00010002,
   GLFW_ACTIVE                = 0x00020001,
    GLFW_ICONIFIED             = 0x00020002,
    GLFW_ACCELERATED           = 0x00020003,
    GLFW_RED_BITS              = 0x00020004,
    GLFW_GREEN_BITS            = 0x00020005,
    GLFW_BLUE_BITS             = 0x00020006,
    GLFW_ALPHA_BITS            = 0x00020007,
    GLFW_DEPTH_BITS            = 0x00020008,
    GLFW_STENCIL_BITS          = 0x00020009,
    GLFW_REFRESH_RATE          = 0x0002000A,
    GLFW_ACCUM_RED_BITS        = 0x0002000B,
    GLFW_ACCUM_GREEN_BITS      = 0x0002000C,
    GLFW_ACCUM_BLUE_BITS       = 0x0002000D,
    GLFW_ACCUM_ALPHA_BITS      = 0x0002000E,
    GLFW_AUX_BUFFERS           = 0x0002000F,
    GLFW_STEREO                = 0x00020010,
    GLFW_WINDOW_NO_RESIZE      = 0x00020011,
    GLFW_FSAA_SAMPLES          = 0x00020012,
    GLFW_OPENGL_VERSION_MAJOR  = 0x00020013,
    GLFW_OPENGL_VERSION_MINOR  = 0x00020014,
    GLFW_OPENGL_FORWARD_COMPAT = 0x00020015,
    GLFW_OPENGL_DEBUG_CONTEXT  = 0x00020016,
    GLFW_OPENGL_PROFILE        = 0x00020017,
    GLFW_OPENGL_CORE_PROFILE   = 0x00000001,
    GLFW_OPENGL_COMPAT_PROFILE = 0x00000002,
    GLFW_OPENGL_ES2_PROFILE    = 0x00000004,
    GLFW_MOUSE_CURSOR          = 0x00030001,
    GLFW_STICKY_KEYS           = 0x00030002,
    GLFW_STICKY_MOUSE_BUTTONS  = 0x00030003,
    GLFW_SYSTEM_KEYS           = 0x00030004,
    GLFW_KEY_REPEAT            = 0x00030005,
    GLFW_PRESENT               = 0x00050001,
    GLFW_AXES                  = 0x00050002,
    GLFW_BUTTONS               = 0x00050003,
    GLFW_NO_ERROR              = 0,
    GLFW_NOT_INITIALIZED       = 0x00070001,
    GLFW_NO_CURRENT_WINDOW     = 0x00070002,
    GLFW_INVALID_ENUM          = 0x00070003,
    GLFW_INVALID_VALUE         = 0x00070004,
    GLFW_OUT_OF_MEMORY         = 0x00070005,
    GLFW_OPENGL_UNAVAILABLE    = 0x00070006,
    GLFW_VERSION_UNAVAILABLE   = 0x00070007,
    GLFW_PLATFORM_ERROR        = 0x00070008,
    GLFW_GAMMA_RAMP_SIZE       = 256
};

typedef struct _GLFWwindow* GLFWwindow;

typedef struct {
            int width;
            int height;
            int redBits;
            int blueBits;
            int greenBits;
} GLFWvidmode;

typedef struct {
            unsigned short red[GLFW_GAMMA_RAMP_SIZE];
            unsigned short green[GLFW_GAMMA_RAMP_SIZE];
            unsigned short blue[GLFW_GAMMA_RAMP_SIZE];
} GLFWgammaramp;

int         glfwInit(                 void );
void        glfwTerminate(            void );
void        glfwGetVersion(           int* major, int* minor, int* rev );
const char* glfwGetVersionString(     void );
int         glfwGetError(             void );
const char* glfwErrorString(          int error );
int         glfwGetVideoModes(        GLFWvidmode* list, int maxcount );
void        glfwGetDesktopMode(       GLFWvidmode* mode );
void        glfwSetGammaFormula(      float gamma, float blacklevel, float gain );
void        glfwGetGammaRamp(         GLFWgammaramp* ramp );
void        glfwSetGammaRamp(   const GLFWgammaramp* ramp );
GLFWwindow  glfwOpenWindow(           int width, int height, int mode, const char* title, GLFWwindow share );
void        glfwOpenWindowHint(       int target, int hint );
void        glfwMakeWindowCurrent(    GLFWwindow window );
int         glfwIsWindow(             GLFWwindow window );
GLFWwindow  glfwGetCurrentWindow(     void );
void        glfwCloseWindow(          GLFWwindow window );
void        glfwSetWindowTitle(       GLFWwindow, const char* title );
void        glfwGetWindowSize(        GLFWwindow, int* width, int* height );
void        glfwSetWindowSize(        GLFWwindow, int  width, int  height );
void        glfwGetWindowPos(         GLFWwindow, int* x, int* y );
void        glfwSetWindowPos(         GLFWwindow, int  x, int  y );
void        glfwIconifyWindow(        GLFWwindow window );
void        glfwRestoreWindow(        GLFWwindow window );
int         glfwGetWindowParam(       GLFWwindow window, int param );
void        glfwSetWindowUserPointer( GLFWwindow window, void* pointer );
void*       glfwGetWindowUserPointer( GLFWwindow window );
void        glfwPollEvents(           void );
void        glfwWaitEvents(           void );
int         glfwGetKey(               GLFWwindow window, int key );
int         glfwGetMouseButton(       GLFWwindow window, int button );
void        glfwGetMousePos(          GLFWwindow window, int* xpos, int* ypos );
void        glfwSetMousePos(          GLFWwindow window, int  xpos, int  ypos );
void        glfwGetScrollOffset(      GLFWwindow window, int* x, int* y );
int         glfwGetJoystickParam(     int joy, int param );
int         glfwGetJoystickPos(       int joy, float* pos, int numaxes );
int         glfwGetJoystickButtons(   int joy, unsigned char* buttons, int numbuttons );
double      glfwGetTime(              void );
void        glfwSetTime(              double time );
void        glfwSwapBuffers(          void );
void        glfwSwapInterval(         int interval );
int         glfwExtensionSupported(   const char* extension );
void*       glfwGetProcAddress(       const char* procname );
void        glfwGetGLVersion(         int* major, int* minor, int* rev );
void        glfwEnable(               GLFWwindow window, int token );
void        glfwDisable(              GLFWwindow window, int token );
]]

local library = {
   ["OSX"]     = "./glfw.dylib",
   ["Windows"] = "./glfw.dll",
   ["Linux"]   = "./glfw.so",
   ["BSD"]     = "./glfw.so",
   ["POSIX"]   = "./glfw.so",
   ["Other"]   = "./glfw.so",
}

return ffi.load( library[ ffi.os ] )

