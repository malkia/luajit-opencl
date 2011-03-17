#!/usr/bin/env luajit 

local ffi = require( "ffi" )
local cl  = require( "cl"  )

local function dump( value )
  if type(value) ~= "table" then
     return tostring(value)
  end
  local s = "{ "
  local c = ""
  for k,v in pairs(value) do
    s = s .. c .. dump(k) .. " = " .. dump(v)
    c = ", "
  end
  s = s .. " }"
  return s;
end

local function test_it()
   for platform_index, platform in pairs( clGetPlatforms() ) 
   do
      for k, v in pairs( platform ) do
	 print( "Platform "..tostring( platform_index )..": "..tostring( k ).." = "..tostring( v ) )
      end
      for device_index,device in pairs( clGetDevices( platform.id ) )
      do
	 local keys = {}
	 for key, _ in pairs( device ) do
	    keys[ #keys + 1 ] = key
	 end
	 table.sort( keys )
	 for _, key in pairs( keys ) do
	    print( "Platform "..tostring( platform_index )..", Device "..tostring( device_index )..": "..tostring( key ).." = "..dump( device[ key ] ))
	 end
      end
   end
end

test_it()

	