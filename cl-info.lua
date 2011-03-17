#!/usr/bin/env luajit 

local ffi = require( "ffi" )
local cl  = require( "cl"  )

function clGetPlatforms()
   local plist = {}

   local num_platforms = ffi.new( "cl_uint[1]" )
   if cl.clGetPlatformIDs( 0, nil, num_platforms ) == cl.CL_SUCCESS 
   then
      local num_platforms = num_platforms[0]
      local platforms = ffi.new( "cl_platform_id[?]", num_platforms )
      if cl.clGetPlatformIDs( num_platforms, platforms, nil ) == cl.CL_SUCCESS 
      then
	 local size = ffi.new( "size_t[1]" )
	 for i = 0, num_platforms - 1 
	 do
	    local prop = { id = platforms[i] }
	    for _, key in ipairs { "name", "vendor", "version", "profile", "extensions" } 
	    do 
	       local info_key = cl["CL_PLATFORM_"..key:upper()]
	       if cl.clGetPlatformInfo( prop.id, info_key, 0, nil, size ) == cl.CL_SUCCESS 
	       then
		  local value_size = size[0]
		  local value = ffi.new( "char[?]", value_size )
		  if cl.clGetPlatformInfo( prop.id, info_key, value_size, value, size ) == cl.CL_SUCCESS 
		  then
		     assert( value_size == size[0] )
		     prop[key] = ffi.string(value, value_size - 1)
		  end
	       end
	    end
	    plist[#plist+1] = prop
	 end
      end
   end

   return plist
end

function clGetDevices(platform_id)
   local plist = {}

   local num_devices = ffi.new( "cl_uint[1]" )
   if cl.clGetDeviceIDs(platform_id, cl.CL_DEVICE_TYPE_ALL, 0, nil, num_devices ) == cl.CL_SUCCESS 
   then
      local num_devices = num_devices[0]
      local devices = ffi.new( "cl_device_id[?]", num_devices )
      if cl.clGetDeviceIDs(platform_id, cl.CL_DEVICE_TYPE_ALL, num_devices, devices, nil) == cl.CL_SUCCESS
      then
	 for i = 0, num_devices-1
	 do
	    local prop = { id = devices[i] }
	    for k,type in pairs {
	       type                          = "cl_device_type",
	       vendor_id                     = "cl_uint",
	       max_compute_units             = "cl_uint",
	       max_work_item_dimensions      = "cl_uint",
	       max_work_item_sizes           = "size_t",
	       max_work_group_size           = "size_t",
	       preferred_vector_width_char   = "cl_uint",  preferred_vector_width_short  = "cl_uint",
	       preferred_vector_width_int    = "cl_uint",  preferred_vector_width_long   = "cl_uint",
	       preferred_vector_width_float  = "cl_uint",  preferred_vector_width_double = "cl_uint",
	       preferred_vector_width_half   = "cl_uint",
	       native_vector_width_char      = "cl_uint",  native_vector_width_short     = "cl_uint",
	       native_vector_width_int       = "cl_uint",  native_vector_width_long      = "cl_uint",
	       native_vector_width_float     = "cl_uint",  native_vector_width_double    = "cl_uint",
	       native_vector_width_half      = "cl_uint",
	       max_clock_frequency           = "cl_uint",
	       address_bits                  = "cl_uint",
	       max_mem_alloc_size            = "cl_ulong",
	       image_support                 = "cl_bool",
	       max_read_image_args           = "cl_uint",
	       max_write_image_args          = "cl_uint",
	       image2d_max_width             = "size_t",  image2d_max_height            = "size_t",
	       image3d_max_width             = "size_t",  image3d_max_height            = "size_t",
	       image3d_max_depth             = "size_t",
	       max_samplers                  = "cl_uint",
	       max_parameter_size            = "size_t",
	       mem_base_addr_align           = "cl_uint",
	       min_data_type_align_size      = "cl_uint",
	       single_fp_config              = "cl_device_fp_config",
	       global_mem_cache_type         = "cl_device_mem_cache_type",
	       global_mem_cacheline_size     = "cl_uint",
	       global_mem_cache_size         = "cl_ulong",
	       global_mem_size               = "cl_ulong",
	       max_constant_buffer_size      = "cl_ulong",
	       max_constant_args             = "cl_uint",
	       local_mem_type                = "cl_device_local_mem_type",
	       local_mem_size                = "cl_ulong",
	       error_correction_support      = "cl_bool",
	       host_unified_memory           = "cl_obol",
	       profiling_timer_resolution    = "size_t",
	       endian_little                 = "cl_bool",
	       available                     = "cl_bool",
	       compiler_available            = "cl_bool",
	       execution_capabilities        = "cl_device_exec_capabilities",
	       queue_properties              = "cl_command_queue_properties",
	       platform                      = "cl_platform_id",
	       name                          = "string",
	       vendor                        = "string",
	       driver_version                = "string",
	       profile                       = "string",
	       version                       = "string",
	       opencl_c_version              = "string",
	       extensions                    = "string",
	    }
	    do
	       local v

	       -- All device information keys are prefixed with CL_DEVICE_ except CL_DRIVER_VERSION
	       if k == "driver_version" then
		  v = cl["CL_"..k:upper()]
	       else
		  v = cl["CL_DEVICE_"..k:upper()]
	       end
	       
	       local value_size = ffi.new( "size_t[1]" )
	       if cl.clGetDeviceInfo( prop.id, v, 0, nil, value_size ) == cl.CL_SUCCESS
	       then
		  local value_size = value_size[0]
		  local ffi_type = (type == "string") and "char" or type
		  local value = ffi.new( ffi_type.."[?]", value_size / ffi.sizeof(ffi_type) )
		  if cl.clGetDeviceInfo( prop.id, v, value_size, value, nil ) == cl.CL_SUCCESS
		  then
		     if type == "string" then
			prop[k] = ffi.string(value, value_size - 1)
		     else
			local ok, v = pcall(tonumber,value[0])
			prop[k] = ok and v or value[0]
		     end
		  end
	       end
	    end
	    plist[#plist+1] = prop
	 end
      end
   end

   return plist
end

local function test_it()
   local platforms = clGetPlatforms()
   for platform_index,platform in pairs(platforms) do
      for k,v in pairs(platform) do
	 print("Plat"..tostring(platform_index)..": "..tostring(k).." = "..tostring(v))
      end
      local devices = clGetDevices(platform.platform_id)
      for device_index,device in pairs(devices) do
	 local keys = {}
	 for key,_ in pairs(device) do
	    keys[#keys+1] = key
	 end
	 table.sort(keys)
	 for _,key in pairs(keys) do
	    print("Plat"..tostring(platform_index)..", Dev"..tostring(device_index)..": "..tostring(key).." = "..tostring(device[key]))
	 end
      end
   end
end

test_it()

