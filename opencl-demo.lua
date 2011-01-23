local cl = require( "opencl" )
local ffi = require( "ffi" )

local function CHK(x)
   if x ~= cl.CL_SUCCESS then
      print("OpenCL error code:",x)
   end
   assert(x == cl.CL_SUCCESS )
   return x
end

local source = [[
      __kernel square( __global float* input, __global float* output, const unsigned int count)
      {                                            
	 int i = get_global_id(0);
	 if( i < count )                 
	     output[i] = input[i] * input[i];
      }                                            
]]

local function demo1(gpu)
   if gpu then
      print( "demo1 using GPU")
   else
      print( "demo1 using CPU")
   end

   local count = 1024

   local device_id = ffi.new("cl_device_id[1]")
   CHK(cl.clGetDeviceIDs(nil, gpu and cl.CL_DEVICE_TYPE_GPU or cl.CL_DEVICE_TYPE_CPU, 1, device_id, nil))

   local err = ffi.new("int[1]")

   local context = cl.clCreateContext(nil, 1, device_id, nil, nil, err)
   assert(CHK(err[0]) and context ~= nil)

   local commands = cl.clCreateCommandQueue(context, device_id[0], 0, err)
   assert(CHK(err[0]) and commands ~= nil)

   local src = ffi.new("char[?]", #source+1, source)
   local src2 = ffi.new("const char*[1]", src)
   local program = cl.clCreateProgramWithSource(context, 1, src2, nil, err)
   assert(CHK(err[0]) and program ~= nil)

   CHK(cl.clBuildProgram(program, 0, nil, nil, nil, nil))

   local kernel = cl.clCreateKernel(program, "square", err)
   assert(CHK(err[0]) and kernel ~= nil)

   local data = ffi.new("float[?]", count)
   for i=0,count-1 do data[i] = (i + 10) end

   local input = cl.clCreateBuffer(context, cl.CL_MEM_READ_ONLY, ffi.sizeof(data), nil, err)
   assert(CHK(err[0]) and input ~= nil)

   local output = cl.clCreateBuffer(context, cl.CL_MEM_WRITE_ONLY, ffi.sizeof(data), nil, err)
   assert(CHK(err[0]) and output ~= nil)

   CHK(cl.clEnqueueWriteBuffer(commands, input, cl.CL_TRUE, 0, ffi.sizeof(data), data, 0, nil, nil))

   local input2 = ffi.new("cl_mem[1]", input)
   CHK(cl.clSetKernelArg(kernel, 0, ffi.sizeof("cl_mem"), input2))

   local output2 = ffi.new("cl_mem[1]", output)
   CHK(cl.clSetKernelArg(kernel, 1, ffi.sizeof("cl_mem"), output2))

   local count2 = ffi.new("int[1]", count)
   CHK(cl.clSetKernelArg(kernel, 2, ffi.sizeof("int"), count2))

   local work_group_size = ffi.new("size_t[1]")
   CHK(cl.clGetKernelWorkGroupInfo(
	  kernel, device_id[0], cl.CL_KERNEL_WORK_GROUP_SIZE, 
	  ffi.sizeof(work_group_size), work_group_size, nil
    ))
   print( "Work Group Size:", work_group_size[0])

   local global = ffi.new("size_t[1]", count)
   CHK(cl.clEnqueueNDRangeKernel(
	  commands, kernel, 1, nil, 
	  global, 
	  work_group_size, 
	  0, nil, nil
    ))

   CHK(cl.clFinish(commands))

   local results = ffi.new("float[?]", count)
   CHK(cl.clEnqueueReadBuffer(commands, output, cl.CL_TRUE, 0, ffi.sizeof(results), results, 0, nil, nil))

   for i=0,count-1 do
      io.stdout:write(results[i])
      io.stdout:write(' ')
   end
   io.stdout:write("\n")

   CHK(cl.clReleaseMemObject(input));
   CHK(cl.clReleaseMemObject(output));
   CHK(cl.clReleaseProgram(program));
   CHK(cl.clReleaseKernel(kernel));
   CHK(cl.clReleaseCommandQueue(commands));
   CHK(cl.clReleaseContext(context));

   print("end!")
end

demo1(true)
demo1(false)

