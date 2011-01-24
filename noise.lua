local ffi = require( "ffi" )
local cl = require( "opencl" )
local gl = require( "opengl" )
local glut = require( "glut" )

local width = 512
local height = 512
local use_gl_attachments = true
local use_gpu = true
local compute_kernels = {
   "GradientNoiseArray2d",
   "MonoFractalArray2d",
   "TurbulenceArray2d",
   "RidgedMultiFractalArray2d"
}

local function main()
   local argc = ffi.new("int[1]", 0)
   glut.glutInit(argc, nil)
   glut.glutInitDisplayMode(glut.GLUT_DOUBLE + glut.GLUT_RGBA + glut.GLUT_DEPTH)
   glut.glutInitWindowSize(width, height)
   glut.glutInitWindowPosition(0, 0)
   glut.glutCreateWindow("noise")
end

main()
