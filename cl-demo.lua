local cl = require( "cl" )
local ffi = require( "ffi" )

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

   devidx = 0
   print( "You chose device index " .. devidx .. " of [0.." .. #devices - 1 .. "]" )
   if devidx < 0 or devidx >= #devices then
      error( "ERROR: ".. #devices .. " devices found. Choose from 0..devices_found-1!" )
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

   print( "PROGRAM ", program )

   CHK(cl.clBuildProgram(program, 0, nil, nil, nil, nil))

   print( "BUILD? " )

   local kernel = cl.clCreateKernel(program, "square", err)
   assert(CHK(err[0]) and kernel ~= nil)

   print( "KERNEL ", kernel )

   local data = ffi.new("float[?]", count)
   for i=0,count-1 do data[i] = (i + 10) end

   print( "DATA ", data )

   local input = cl.clCreateBuffer(context, cl.CL_MEM_READ_ONLY, ffi.sizeof(data), nil, err)
   assert(CHK(err[0]) and input ~= nil)

   print( "INPUT ", input )

   local output = cl.clCreateBuffer(context, cl.CL_MEM_WRITE_ONLY, ffi.sizeof(data), nil, err)
   assert(CHK(err[0]) and output ~= nil)

   print( "OUTPUT ", output )

   CHK(cl.clEnqueueWriteBuffer(commands, input, cl.CL_TRUE, 0, ffi.sizeof(data), data, 0, nil, nil))

   print( "ENQUEUED? " )

   local input2 = ffi.new("cl_mem[1]", input)
   CHK(cl.clSetKernelArg(kernel, 0, ffi.sizeof("cl_mem"), input2))
   
   print( "INPUT2 ", input2 )

   local output2 = ffi.new("cl_mem[1]", output)
   CHK(cl.clSetKernelArg(kernel, 1, ffi.sizeof("cl_mem"), output2))

   print( "OUTPUT2 ", output2 )

   local count2 = ffi.new("int[1]", count)
   CHK(cl.clSetKernelArg(kernel, 2, ffi.sizeof("int"), count2))

   print( "COUNT2 ", count2 )

   local work_group_size = ffi.new("size_t[1]")
   CHK(cl.clGetKernelWorkGroupInfo(
	  kernel, ffi_device[0], cl.CL_KERNEL_WORK_GROUP_SIZE, 
	  ffi.sizeof(work_group_size), work_group_size, nil
    ))

   print( "WORK GROUP SIZE ", work_group_size[0] )

   local global = ffi.new("size_t[1]", count)
   CHK(cl.clEnqueueNDRangeKernel(
	  commands, kernel, 1, nil, 
	  global, 
	  work_group_size, 
	  0, nil, nil
    ))

   print( "ENQUEUE-ND-RANGE-KERNEL? " )

   CHK(cl.clFinish(commands))

   local results = ffi.new("float[?]", count)
   CHK(cl.clEnqueueReadBuffer(commands, output, cl.CL_TRUE, 0, ffi.sizeof(results), results, 0, nil, nil))

   for i=0,count-1 do
      io.stdout:write(results[i])
      io.stdout:write('\t')
   end
   io.stdout:write("\n")

   CHK(cl.clReleaseMemObject(input));
   CHK(cl.clReleaseMemObject(output));
   CHK(cl.clReleaseProgram(program));
   CHK(cl.clReleaseKernel(kernel));
   CHK(cl.clReleaseCommandQueue(commands));
   CHK(cl.clReleaseContext(context));

   print( "END!" )
end

--demo1(true)
demo1(0)

