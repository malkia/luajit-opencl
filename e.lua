local ffi, bit = require( "ffi" ), require( "bit" )
local gl, glfw = require( "gl" ), require( "glfw" )

local font = require( "x-font" )
local font = ffi.new( "uint8_t[?]", #font, font )

local random = math.random
local lshift, rshift, band = bit.lshift, bit.rshift, bit.band
local cos, sin = math.cos, math.sin

local desktop_width = 0
local desktop_height = 0
local window_width = 640
local window_height = 480

local vbo_capacity = 1920*1280*2
local vbo_index = 0
local vbo = ffi.new( "float[?]", vbo_capacity )

local angle = 0
local cos_angle = 0
local sin_angle = 1

local function draw_char(x,y,c)
   if c <= 1 or c >= 127 then
      c = 1
   end
   x = x + 4
   y = y + 4
   c = c * 8
   for i=0,7 do
      local b = font[c + i]
      for j=0,7 do
	 if band(b, lshift(1, 7-j)) ~= 0 then
	    vbo[ vbo_index + 0 ] = x + j
	    vbo[ vbo_index + 1 ] = y + i
	    vbo_index = vbo_index + 2
	 end
      end
   end
end

local function draw_string(x,y,s,draw_char_function)
   for i=1,#s do
      local c = s:byte(i)
      if c == 10 or c == 13 then
	 y = y + 9
	 if y + 9 > window_height then
	    break
	 end
	 x = 0
      else
	 draw_char(x,y,c)
	 x = x + 8
      end
   end
end

local function read_file(n)
   local f = io.input(n)
   return f:read("*all")
end

local text = read_file("x-font.lua")

local fullscreen = false

local function main()
   local frame = 0
   local c = 0
   assert( glfw.glfwInit() )
   local desktop_mode = ffi.new( "GLFWvidmode[1]" )
   glfw.glfwGetDesktopMode( desktop_mode )
   desktop_width, desktop_height = desktop_mode[0].width, desktop_mode[0].height
   local window_x = ( desktop_width - window_width ) / 2
   local window_y = ( desktop_height - window_height ) / 2
--   glfw.glfwOpenWindowHint(glfw.GLFW_WINDOW_NO_RESIZE, 1)
   local window = glfw.glfwOpenWindow( window_width, window_height, glfw.GLFW_WINDOWED, "E", nil )
   assert( window )
   glfw.glfwSetWindowPos(window, window_x, window_y)
--   glfw.glfwEnable(window, glfw.GLFW_STICKY_KEYS)
   glfw.glfwSwapInterval(0);
   local ct = glfw.glfwGetTime()
   local pt = glfw.glfwGetTime()
   while glfw.glfwIsWindow(window) 
   and   glfw.glfwGetKey(window, glfw.GLFW_KEY_ESCAPE) ~= glfw.GLFW_PRESS 
   do
      pt, ct = ct, glfw.glfwGetTime()
      frame = frame + 1
      
      local width, height = ffi.new( "int[1]" ), ffi.new( "int[1]" )
      glfw.glfwGetWindowSize(window, width, height);
      width, height = width[0], height[0]
      window_width, window_height = width, height
      
      gl.glViewport(0, 0, width, height);
      gl.glClear(gl.GL_COLOR_BUFFER_BIT);
      
      gl.glMatrixMode(gl.GL_PROJECTION);
      gl.glLoadIdentity();
      gl.glOrtho(0, width, height, 0, 0, 1)
      
      gl.glMatrixMode( gl.GL_MODELVIEW );
      gl.glLoadIdentity();
 
      draw_string( 0, 0, tostring(ct-pt), draw_char_normal )
      draw_string( 0, 0 + 9, text )

      gl.glEnableClientState(gl.GL_VERTEX_ARRAY);
      gl.glVertexPointer(2, gl.GL_FLOAT, 0, vbo);
      if vbo_index > 0 then 
         gl.glDrawArrays(gl.GL_POINTS, 0, vbo_index);
	 vbo_index = 0
      end
      gl.glDisableClientState(gl.GL_VERTEX_ARRAY);

      glfw.glfwSwapBuffers();
      glfw.glfwPollEvents();
   end
   glfw.glfwTerminate();
end

main()
