local ffi, bit = require( "ffi" ), require( "bit" )
local gl, glfw = require( "gl" ), require( "glfw" )

local font = require( "x-font" )
local font = ffi.new( "uint8_t[?]", #font, font )

local random = math.random
local rshift, band = bit.rshift, bit.band

local signal_noise = 0

local function draw_char(x,y,c)
   if random()*signal_noise > 0.25 then
      c = c + 1
   end
   c = c * 8
   gl.glColor3f( signal_noise, 1 - signal_noise, random() )
   for i=0,7 do
      local b = font[c + i]
      for j=0,7 do
	 local m = band(rshift(b, 7-j), 1)
	 if m == 1 and random() >= signal_noise then
	    gl.glVertex3f(x+j+random()*signal_noise,y+i+random()*signal_noise,0)
	 end
      end
   end
end

local function draw_string(x,y,s)
   gl.glBegin( gl.GL_POINTS )
   for i=1,#s do
      local c = s:byte(i)
      if c == 10 or c == 13 then
	 y = y + 8 
	 if y > 480 then
	    break
	 end
	 x = 0
      else
--	 draw_char(x+random(),y+random(),c)
	 draw_char(x,y,c)
	 x = x + 8
      end
   end
   gl.glEnd()
end

local function read_file(n)
   local f = io.input(n)
   return f:read("*all")
end

local text = read_file("x-font.lua")

local function main()
   local frame = 0
   local c = 0
   assert( glfw.glfwInit() )
   glfw.glfwOpenWindowHint(glfw.GLFW_WINDOW_NO_RESIZE, 1)
   local window = glfw.glfwOpenWindow( 640, 480, glfw.GLFW_WINDOWED, "X", nil )
   assert( window )
   glfw.glfwEnable(window, glfw.GLFW_STICKY_KEYS);
--   glfw.glfwSwapInterval(1);
   local ct = glfw.glfwGetTime()
   local pt = glfw.glfwGetTime()
   while glfw.glfwIsWindow(window) and glfw.glfwGetKey(window, glfw.GLFW_KEY_ESCAPE) ~= glfw.GLFW_PRESS 
   do
      local x, y = ffi.new( "int[1]" ), ffi.new( "int[1]" )
      glfw.glfwGetMousePos(window, x, y)
      x, y = x[0], y[0]

      local width, height = ffi.new( "int[1]" ), ffi.new( "int[1]" )
      glfw.glfwGetWindowSize(window, width, height);
      width, height = width[0], height[0]

      gl.glViewport(0, 0, width, height);
      gl.glClearColor(0, 0, 0, 0);
      gl.glClear(gl.GL_COLOR_BUFFER_BIT);

      gl.glMatrixMode(gl.GL_PROJECTION);
      gl.glLoadIdentity();
      gl.glOrtho(0, width, height, 0, 0, 1)
      
      gl.glMatrixMode( gl.GL_MODELVIEW );
      gl.glLoadIdentity();
 
      if random() * signal_noise > 0.75 then
	 gl.glBegin(gl.GL_POLYGON);
	 gl.glVertex3f(0.25*width, 0.25*height, 0.0);
	 gl.glVertex3f(0.75*width, 0.25*height, 0.0);
	 gl.glVertex3f(0.75*width, 0.75*height, 0.0);
	 gl.glVertex3f(0.25*width, 0.75*height, 0.0);
	 gl.glEnd();
      end

      draw_string( 0.5, 0.5, tostring(ct-pt).."\n"..string.sub(text,math.mod(0,#text)))
      frame = frame + 1

      signal_noise = signal_noise + (random() - 0.5) / 10.0
      if signal_noise < 0 then
	 signal_noise = 0
      end
      
      if signal_noise > 1 then
	 signal_noise = 1
      end
      
      glfw.glfwSwapBuffers();
      glfw.glfwPollEvents();
      pt, ct = ct, glfw.glfwGetTime()
   end
   glfw.glfwTerminate();
end

main()
