#!/usr/bin/env luajit

ffi = require( "ffi" )
cl  = require( "cl" )
cl_error = nil
cl_error_buf = ffi.new( "int[1]" )

local function CODE(x)
   for c,r in ipairs(x) do
      for k,v in pairs(x) do
	 if type(k) == "string" then
	    r = r:gsub( "@"..k, v )
	 end
      end
      local fun, msg = loadstring( r ) 
      if fun == nil then
	 local col = msg:find(':')
	 msg = msg:sub(col)
	 error( "\nERROR" .. msg .. " IN SOURCE CODE:\n" .. x[c] .. "\nEXPANDED TO:\n" .. r )
      end
      fun()
   end
end

local function CHK(x)
   if x ~= cl.CL_SUCCESS then
      print("OpenCL error code:",x)
   end
   assert(x == cl.CL_SUCCESS )
   return x
end

local source = [[
      __kernel void square(__global const float* input, __global float* output, const unsigned int count)
      {                                            
	 int i = get_global_id(0);
	 if( i < count )                 
	     output[i] = input[i] * input[i];
      }
]]

function clEnqueueNDRangeKernel(queue, kernel, global_offsets, global_sizes, local_sizes)
   local dim = #global_sizes
   if (global_offsets ~= nil and dim ~= #global_offsets) or dim ~= #local_sizes then
      error( "clEnqueueNDRangeKernel: global_sizes must have the same dimension of local_sizes and global_offsets, unless global_offsets is nil" )
   end
   local gwo
   if #global_offsets ~= nil then
      gwo = ffi.new( "size_t[?]", dim, global_offsets )
   end
   local gws = ffi.new( "size_t[?]", dim, global_sizes )
   local lws = ffi.new( "size_t[?]", dim, local_sizes )
   local err = cl.clEnqueueNDRangeKernel(queue, kernel, dim, gwo, gws, lws, 0, nil, nil)
   if err ~= cl.CL_SUCCESS then
      error( "clEnqueueNDRangeKernel: " .. err )
   end
end

function clBuildProgram(program, devices, options)
   local err = ffi.new( "int[1]" )
   local kernel = cl.clBuildProgram(program, n_dev, dev, options, nil, nil)
   if err[0] ~= cl.CL_SUCCESS then
      error( "clBuildProgram: " .. err[0] )
   end
   return kernel
end

function defcl1(name, args, callargs)
   CODE {
      name = name,
      args = args,
      callargs = callargs or args,
      [[
	    function @name(@args)
	       print(cl)
	       cl_error = cl.@name(@callargs)
	       if cl_error ~= cl.CL_SUCCESS then
		  error( "@name: " .. cl_error )
	       end
	    end
      ]]
   }
end

function defcl2(name, args, callargs)
   CODE {
      name = name,
      args = args,
      callargs = callargs or args,
      [[
	    function @name(@args)
	       local obj = cl.@name(@callargs, cl_error_buf)
	       cl_error = cl_error_buf[0]
	       if cl_error ~= cl.CL_SUCCESS then
		  error( "@name: " .. cl_error )
	       end
	       return obj
	    end
      ]]
   }
end

local function wrap1(func, args)
   _G[func] = function()
		 local err = cl[func](args)
		 if err ~= cl.CL_SUCCESS then
		    error( func .. ": " .. err )
		 end
	      end
end


-- cl.clGetPlatformIDS         -> clGetPlatforms
-- cl.clGetPlatformInfo        -> clGetPlatforms
-- cl.clGetDeviceIDs           -> clGetDevices
-- cl.clGetDeviceInfo          -> clGetDevices
-- cl.clCreateContext          -> clCreateContext
defcl1( "clRetainContext",       "cl_context" )
defcl1( "clReleaseContext",      "cl_context" )
defcl1( "clFinish",              "queue"  )
defcl1( "clReleaseMemObject",    "input"  )
defcl1( "clReleaseProgram",      "program"  )
defcl1( "clReleaseKernel",       "kernel"  )
defcl1( "clReleaseCommandQueue", "queue"   )
defcl1( "clReleaseContext",      "context" )
defcl1( "clSetKernelArg",        "kernel, index, data", "kernel, index, ffi.sizeof(data), data" )

defcl2( "clCreateKernel",        "program, kernel_name" )
defcl2( "clCreateBuffer",        "context, type, size", "context, type, size, nil" )


wrap1( "clRetainContext", "cl_context" )
wrap1( "clUnloadCompiler", "" )

clUnloadCompiler()

--[[
local function demo1( devidx )
   local count = 1024
   
   local devices = {}
   for platform_index, platform in pairs(clGetPlatforms()) do
      local platform_devices = clGetDevices(platform.id)
      for device_index, device in pairs(platform_devices) do
	 devices[ #devices + 1 ] = device
      end
   end

   local ffi_devices = ffi.new( "cl_device_id[?]", #devices )
   for k, _ in ipairs( devices ) do
      ffi_devices[k-1] = devices[ k ].id
      print( devices[k].id )
   end

   devidx = 1
   print( "You chose device index " .. devidx .. " of [0.." .. #devices - 1 .. "]" )
   if devidx < 0 or devidx >= #devices then
      error( "ERROR: ".. #devices .. " devices found. Choose from 0.." .. #devices - 1 .. "!" )
   end
   local ffi_device = ffi.new( "cl_device_id[1]", ffi_devices[devidx] )

   local err = ffi.new( "int[1]" )
   local context_properties = ffi.new( "cl_context_properties[3]", cl.CL_CONTEXT_PLATFORM, ffi.cast("intptr_t",devices[devidx+1].platform), ffi.cast("intptr_t", nil) )
   local context = cl.clCreateContext(context_properties, 1, ffi_device, nil, nil, err)
   assert(CHK(err[0]) and context ~= nil)

   print( "CONTEXT ", context )

   local context_info = clGetContextInfo(context)
   
   print( "INFO ", context_info )
   for k,v in pairs(context_info) do print(k,v) end

   local commands = cl.clCreateCommandQueue(context, ffi_device[0], 0, err)
   assert(CHK(err[0]) and commands ~= nil)

   print( "COMMANDS ", commands )

   local src = ffi.new("char[?]", #source+1, source)
   local src2 = ffi.new("const char*[1]", src)
   local program = cl.clCreateProgramWithSource(context, 1, src2, nil, err)
   assert(CHK(err[0]) and program ~= nil)

   CHK(cl.clBuildProgram(program, 0, nil, nil, nil, nil))

   local kernel = cl.clCreateKernel(program, "square", err)
   assert(CHK(err[0]) and kernel ~= nil)

   print( "KERNEL ", kernel )

   local data = ffi.new("float[?]", count)
   for i=0,count-1 do data[i] = (i + 10) end

   print( "DATA ", data )

   local input  = clCreateBuffer(context, cl.CL_MEM_READ_ONLY,  ffi.sizeof(data))
   local output = clCreateBuffer(context, cl.CL_MEM_WRITE_ONLY, ffi.sizeof(data))

   CHK(cl.clEnqueueWriteBuffer(commands, input, cl.CL_TRUE, 0, ffi.sizeof(data), data, 0, nil, nil))

   print( "ENQUEUED? " )

   local input2 = ffi.new("cl_mem[1]", input)
   clSetKernelArg(kernel, 0, input2)

   local output2 = ffi.new("cl_mem[1]", output)
   clSetKernelArg(kernel, 1, output2)

   local count2 = ffi.new("int[1]", count)
   clSetKernelArg(kernel, 2, count2)

   local work_group_info = clGetKernelWorkGroupInfo( kernel, ffi_device[0] )
   local work_group_size = work_group_info.work_group_size
   clEnqueueNDRangeKernel( commands, kernel, nil, { count }, work_group_info.work_group_size )
   clFinish( commands )

   local results = ffi.new("float[?]", count)
   CHK(cl.clEnqueueReadBuffer(commands, output, cl.CL_TRUE, 0, ffi.sizeof(results), results, 0, nil, nil))

   for i=0,count-1 do
      io.stdout:write(results[i])
      io.stdout:write('\t')
   end
   io.stdout:write("\n")

   clReleaseMemObject(input);
   clReleaseMemObject(output);
   clReleaseProgram(program);
   clReleaseKernel(kernel);
   clReleaseCommandQueue(commands);
   clReleaseContext(context);

   print( "END!" )
end

--demo1(true)
demo1(0)
--]]