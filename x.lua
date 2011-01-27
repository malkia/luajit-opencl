local ffi, bit = require( "ffi" ), require( "bit" )
local gl, glfw = require( "gl" ), require( "glfw" )

local font = require( "x-font" )
local font = ffi.new( "uint8_t[?]", #font, font )

local random = math.random
local rshift, band = bit.rshift, bit.band
local cos, sin = math.cos, math.sin

local signal_noise = 0

local desktop_width = 0
local desktop_height = 0
local width = 640
local height = 480

local vbo_capacity = width*height*2
local vbo_index = 0
local vbo = ffi.new( "float[?]", vbo_capacity )

local angle = 0
local cos_angle = 0
local sin_angle = 1

local function draw_char(x,y,c)
   if random()*signal_noise > 0.25 then
      c = c + 1
   end
   c = c * 8
   for i=0,7 do
      local b = font[c + i]
      for j=0,7 do
	 local m = band(rshift(b, 7-j), 1)
	 if m == 1 and random() >= signal_noise then
	    local x = x + j + random()*signal_noise
	    local y = y + i + random()*signal_noise
	    x = x - width / 2
	    y = y - height / 2
	    vbo[ vbo_index + 0 ] = (x * cos_angle - y * sin_angle) * (1.00 + signal_noise * random() / 4.0) * 1.4 + width / 2 
	    vbo[ vbo_index + 1 ] = (y * cos_angle + x * sin_angle) * (1.00 + signal_noise * random() / 4.0) * 1.4 + height / 2
	    vbo_index = vbo_index + 2
	 end
      end
   end
end

local function draw_char_normal(x,y,c)
   c = c * 8
   for i=0,7 do
      local b = font[c + i]
      for j=0,7 do
	 local m = band(rshift(b, 7-j), 1)
	 if m == 1 then
	    vbo[ vbo_index + 0 ] = x + j
	    vbo[ vbo_index + 1 ] = y + i
	    vbo_index = vbo_index + 2
	 end
      end
   end
end

local function draw_string(x,y,s,draw_char_function)
   draw_char_function = draw_char_function or draw_char
   for i=1,#s do
      local c = s:byte(i)
      if c == 10 or c == 13 then
	 y = y + 8 
	 if y > height then
	    break
	 end
	 x = 0
      else
	 draw_char_function(x,y,c)
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
   local window_x = ( desktop_width - width ) / 2
   local window_y = ( desktop_height - height ) / 2
   glfw.glfwOpenWindowHint(glfw.GLFW_WINDOW_NO_RESIZE, 1)
   local window = glfw.glfwOpenWindow( width, height, glfw.GLFW_WINDOWED, "X", nil )
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
      
      gl.glPointSize(random()*signal_noise)
      
      gl.glColor3f( signal_noise, 1 - signal_noise, random() )
      if random() * signal_noise < 0.30 then
	 gl.glClear(gl.GL_COLOR_BUFFER_BIT);
      end

      gl.glMatrixMode(gl.GL_PROJECTION);
      gl.glLoadIdentity();
      gl.glOrtho(0, width, height, 0, 0, 1)
      
      gl.glMatrixMode( gl.GL_MODELVIEW );
      gl.glLoadIdentity();
 
      draw_string( 0.5, 0.5, tostring(ct-pt), draw_char_normal )
      draw_string( 0.5, 0.5 + 10, text )

      signal_noise = signal_noise + (random() - 0.5) / 10.0
      if signal_noise < 0 then
	 signal_noise = 0
      end
      
      if signal_noise > 1 then
	 signal_noise = 1
      end

      gl.glEnableClientState(gl.GL_VERTEX_ARRAY);
      gl.glVertexPointer(2, gl.GL_FLOAT, 0, vbo);
      gl.glDrawArrays(gl.GL_POINTS, 0, vbo_index);
      gl.glDisableClientState(gl.GL_VERTEX_ARRAY);
      vbo_index = 0
      
      angle = angle + signal_noise / 10.0 * random() - 0.01
      cos_angle = cos( angle )
      sin_angle = sin( angle )

      if glfw.glfwGetKey(window, glfw.GLFW_KEY_SPACE) == glfw.GLFW_PRESS then
	 print(fullscreen)
	 fullscreen = not fullscreen
	 if fullscreen then
	        new_window = glfw.glfwOpenWindow( width, height, glfw.GLFW_FULLSCREEN, "X", window )
                glfw.glfwSwapInterval(1);
	 else
	        new_window = glfw.glfwOpenWindow( width, height, glfw.GLFW_WINDOWED, "X", window )
                glfw.glfwSetWindowPos(new_window, window_x, window_y)
                glfw.glfwSwapInterval(0);
	 end
	 glfw.glfwCloseWindow(window)
	 window = new_window
      end
      
      glfw.glfwSwapBuffers();
      glfw.glfwPollEvents();
   end
   glfw.glfwTerminate();
end

main()
