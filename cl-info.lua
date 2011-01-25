local cl = require( "cl" )
local ffi = require( "ffi" )

local function CHK(x)
   if x ~= cl.CL_SUCCESS then
      print("OpenCL error code:",x)
   end
   assert(x == cl.CL_SUCCESS )
   return x
end

local cl_uint = ffi.typeof("cl_uint[?]")
local cl_bool = ffi.typeof("cl_bool[?]")
local cl_platform_id = ffi.typeof("cl_platform_id[?]")
local size_t = ffi.typeof("size_t[?]")
local char = ffi.typeof("char[?]")
local cl_device_fp_config = ffi.typeof("cl_device_fp_config[?]")

function clGetPlatforms()
   local num_platforms = cl_uint(1)
   if cl.clGetPlatformIDs(0, nil, num_platforms) == cl.CL_SUCCESS then
      local num_platforms = num_platforms[0]
      local platforms = cl_platform_id(num_platforms)
      local r = {}
      if cl.clGetPlatformIDs(num_platforms, platforms, nil) == cl.CL_SUCCESS then
	 for i = 0, num_platforms-1 do
	    local id = platforms[i]
	    local p = {}
	    p.id = id
	    for k,v in pairs { 
	       name = cl.CL_PLATFORM_NAME,
	       vendor = cl.CL_PLATFORM_VENDOR,
	       version = cl.CL_PLATFORM_VERSION,
	       profile = cl.CL_PLATFORM_PROFILE,
	       extensions = cl.CL_PLATFORM_EXTENSIONS }
	    do 
	       local value_size = size_t(1)
	       if cl.clGetPlatformInfo(id, v, 0, nil, value_size) == cl.CL_SUCCESS then
		  local value_size = value_size[0]
		  local value = char( value_size )
		  if cl.clGetPlatformInfo(id, v, value_size, value, nil) == cl.CL_SUCCESS then
		     local value = ffi.string(value)
		     p[k] = value
		  end
	       end
	    end
	    r[#r+1] = p
	 end
	 return r;
      end
   end
end

function clGetDevices(platform_id)
   local num_devices = cl_uint(1)
   if cl.clGetDeviceIDs(platform_id, cl.CL_DEVICE_TYPE_ALL, 0, nil, num_devices ) == cl.CL_SUCCESS then
      local num_devices = num_devices[0]
      local devices = cl_device_id(num_devices)
      if cl.clGetDeviceIDs(platform_id, cl.CL_DEVICE_TYPE_ALL, num_devices, devices, 0) == cl.CL_SUCESS then
	 for i = 0, num_devices-1 do
	    local id = devices[i]
	    local p = {}
	    p.id = id
	    for k,v in pairs {
	       address_bits = { cl.CL_DEVICE_ADDRESS_BITS, cl_uint, 1 },
	       available = { cl.CL_DEVICE_AVAILABLE, cl_bool, 1 },
	       compiler_available = { cl.CL_DEVICE_COMPILER_AVAILABLE, cl_bool },
	       double_fp_config = { cl.CL_DEVICE_DOUBLE_FP_CONFIG, cl_device_fp_config },
	       endian_little = { cl.CL_CL_DEVICE_ENDIAN_LITTLE, cl_bool },
	       error_correction_support = { cl.CL_DEVICE_ERROR_CORRECTION_SUPPORT, cl_bool },
	       execution_capabilities = { cl.CL_DEVICE_EXECUTION_CAPABILITIES, cl_bool }, }
	    do
	       local value_size = size_t(1)
	       if cl.clGetDeviceInfo(id, v[1], 0, nil, value_size) == cl.CL_SUCCESS then
		  local value_size = value_size[0]
		  local value = v[2]( value_size )
		  if cl.clGetDeviceInfo(id, v[1], value_size, value, nil) == cl.CL_SUCCESS then
		     -- Not finished
		  end
	       end
	       print(k, v)
	    end
	 end
      end
   end
end

local platforms = clGetPlatforms()

for _,platform in pairs(platforms) do
  for k,v in pairs(platform) do
     print(tostring(k).." = "..tostring(v))
  end
  print("\n")
end

