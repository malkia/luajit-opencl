local ffi = require( "ffi" )
local cl = require( "cl" )
local gl = require( "gl" )
local glu = require( "glu" )
local glfw = require( "glfw" )

local noise_kernel = [==[
      #define ONE_F1                 (1.0f)
      #define ZERO_F1                (0.0f)

      #define USE_IMAGES_FOR_RESULTS (0)  // NOTE: It may be faster to use buffers instead of images

      static const float4 ZERO_F4 = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
      static const float4 ONE_F4 = (float4)(1.0f, 1.0f, 1.0f, 1.0f);

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      __constant int P_MASK = 255;
      __constant int P_SIZE = 256;
      __constant int P[512] = {151,160,137,91,90,15,
			       131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
			       190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
			       88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
			       77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
			       102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
			       135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
			       5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
			       223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
			       129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
			       251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
			       49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
			       138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
			       151,160,137,91,90,15,
			       131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
			       190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
			       88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
			       77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
			       102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
			       135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
			       5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
			       223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
			       129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
			       251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
			       49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
			       138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,  
			    };

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      __constant int G_MASK = 15;
      __constant int G_SIZE = 16;
      __constant int G_VECSIZE = 4;
      __constant float G[16*4] = {
	    +ONE_F1,  +ONE_F1, +ZERO_F1, +ZERO_F1, 
	    -ONE_F1,  +ONE_F1, +ZERO_F1, +ZERO_F1, 
	    +ONE_F1,  -ONE_F1, +ZERO_F1, +ZERO_F1, 
	    -ONE_F1,  -ONE_F1, +ZERO_F1, +ZERO_F1,
	    +ONE_F1, +ZERO_F1,  +ONE_F1, +ZERO_F1, 
	    -ONE_F1, +ZERO_F1,  +ONE_F1, +ZERO_F1, 
	    +ONE_F1, +ZERO_F1,  -ONE_F1, +ZERO_F1, 
	    -ONE_F1, +ZERO_F1,  -ONE_F1, +ZERO_F1,
	    +ZERO_F1,  +ONE_F1,  +ONE_F1, +ZERO_F1, 
	    +ZERO_F1,  -ONE_F1,  +ONE_F1, +ZERO_F1, 
	    +ZERO_F1,  +ONE_F1,  -ONE_F1, +ZERO_F1, 
	    +ZERO_F1,  -ONE_F1,  -ONE_F1, +ZERO_F1,
	    +ONE_F1,  +ONE_F1, +ZERO_F1, +ZERO_F1, 
	    -ONE_F1,  +ONE_F1, +ZERO_F1, +ZERO_F1, 
	    +ZERO_F1,  -ONE_F1,  +ONE_F1, +ZERO_F1, 
	    +ZERO_F1,  -ONE_F1,  -ONE_F1, +ZERO_F1
      };  
      
      ////////////////////////////////////////////////////////////////////////////////////////////////////

      int mod(int x, int a)
      {
	 int n = (x / a);
	 int v = v - n * a;
	 if ( v < 0 )
	 v += a;
	 return v;	
      }

      float smooth(float t)
      {
	 return t*t*t*(t*(t*6.0f-15.0f)+10.0f); 
      }

      float4 normalized(float4 v)
      {
	 float d = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
	 d = d > 0.0f ? d : 1.0f;
	 float4 result = (float4)(v.x, v.y, v.z, 0.0f) / d;
	 result.w = 1.0f;
	 return result;
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////
      
      float mix1d(float a, float b, float t)
      {
	 float ba = b - a;
	 float tba = t * ba;
	 float atba = a + tba;
	 return atba;	
      }

      float2 mix2d(float2 a, float2 b, float t)
      {
	 float2 ba = b - a;
	 float2 tba = t * ba;
	 float2 atba = a + tba;
	 return atba;	
      }

      float4 mix3d(float4 a, float4 b, float t)
      {
	 float4 ba = b - a;
	 float4 tba = t * ba;
	 float4 atba = a + tba;
	 return atba;	
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      int lattice1d(int i)
      {
	 return P[i];
      }

      int lattice2d(int2 i)
      {
	 return P[i.x + P[i.y]];
      }

      int lattice3d(int4 i)
      {
	 return P[i.x + P[i.y + P[i.z]]];
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      float gradient1d(int i, float v)
      {
	 int index = (lattice1d(i) & G_MASK) * G_VECSIZE;
	 float g = G[index + 0];
	 return (v * g);
      }

      float gradient2d(int2 i, float2 v)
      {
	 int index = (lattice2d(i) & G_MASK) * G_VECSIZE;
	 float2 g = (float2)(G[index + 0], G[index + 1]);
	 return dot(v, g);
      }

      float gradient3d(int4 i, float4 v)
      {
	 int index = (lattice3d(i) & G_MASK) * G_VECSIZE;
	 float4 g = (float4)(G[index + 0], G[index + 1], G[index + 2], 1.0f);
	 return dot(v, g);
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      // Signed gradient noise 1d
      float sgnoise1d(float position)
      {
	 float p = position;
	 float pf = floor(p);
	 int ip = (int)pf;
	 float fp = p - pf;        
	 ip &= P_MASK;
	 
	 float n0 = gradient1d(ip + 0, fp - 0.0f);
	 float n1 = gradient1d(ip + 1, fp - 1.0f);

	 float n = mix1d(n0, n1, smooth(fp));
	 return n * (1.0f / 0.7f);
      }

      // Signed gradient noise 2d
      float sgnoise2d(float2 position)
      {
	 float2 p = position;
	 float2 pf = floor(p);
	 int2 ip = (int2)((int)pf.x, (int)pf.y);
	 float2 fp = p - pf;        
	 ip &= P_MASK;
	 
	 const int2 I00 = (int2)(0, 0);
	 const int2 I01 = (int2)(0, 1);
	 const int2 I10 = (int2)(1, 0);
	 const int2 I11 = (int2)(1, 1);
	 
	 const float2 F00 = (float2)(0.0f, 0.0f);
	 const float2 F01 = (float2)(0.0f, 1.0f);
	 const float2 F10 = (float2)(1.0f, 0.0f);
	 const float2 F11 = (float2)(1.0f, 1.0f);

	 float n00 = gradient2d(ip + I00, fp - F00);
	 float n10 = gradient2d(ip + I10, fp - F10);
	 float n01 = gradient2d(ip + I01, fp - F01);
	 float n11 = gradient2d(ip + I11, fp - F11);

	 const float2 n0001 = (float2)(n00, n01);
	 const float2 n1011 = (float2)(n10, n11);

	 float2 n2 = mix2d(n0001, n1011, smooth(fp.x));
	 float n = mix1d(n2.x, n2.y, smooth(fp.y));
	 return n * (1.0f / 0.7f);
      }

      // Signed gradient noise 3d
      float sgnoise3d(float4 position)
      {

	 float4 p = position;
	 float4 pf = floor(p);
	 int4 ip = (int4)((int)pf.x, (int)pf.y, (int)pf.z, 0.0);
	 float4 fp = p - pf;        
	 ip &= P_MASK;

	 int4 I000 = (int4)(0, 0, 0, 0);
	 int4 I001 = (int4)(0, 0, 1, 0);  
	 int4 I010 = (int4)(0, 1, 0, 0);
	 int4 I011 = (int4)(0, 1, 1, 0);
	 int4 I100 = (int4)(1, 0, 0, 0);
	 int4 I101 = (int4)(1, 0, 1, 0);
	 int4 I110 = (int4)(1, 1, 0, 0);
	 int4 I111 = (int4)(1, 1, 1, 0);
	 
	 float4 F000 = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
	 float4 F001 = (float4)(0.0f, 0.0f, 1.0f, 0.0f);
	 float4 F010 = (float4)(0.0f, 1.0f, 0.0f, 0.0f);
	 float4 F011 = (float4)(0.0f, 1.0f, 1.0f, 0.0f);
	 float4 F100 = (float4)(1.0f, 0.0f, 0.0f, 0.0f);
	 float4 F101 = (float4)(1.0f, 0.0f, 1.0f, 0.0f);
	 float4 F110 = (float4)(1.0f, 1.0f, 0.0f, 0.0f);
	 float4 F111 = (float4)(1.0f, 1.0f, 1.0f, 0.0f);
	 
	 float n000 = gradient3d(ip + I000, fp - F000);
	 float n001 = gradient3d(ip + I001, fp - F001);
	 
	 float n010 = gradient3d(ip + I010, fp - F010);
	 float n011 = gradient3d(ip + I011, fp - F011);
	 
	 float n100 = gradient3d(ip + I100, fp - F100);
	 float n101 = gradient3d(ip + I101, fp - F101);

	 float n110 = gradient3d(ip + I110, fp - F110);
	 float n111 = gradient3d(ip + I111, fp - F111);

	 float4 n40 = (float4)(n000, n001, n010, n011);
	 float4 n41 = (float4)(n100, n101, n110, n111);

	 float4 n4 = mix3d(n40, n41, smooth(fp.x));
	 float2 n2 = mix2d(n4.xy, n4.zw, smooth(fp.y));
	 float n = mix1d(n2.x, n2.y, smooth(fp.z));
	 return n * (1.0f / 0.7f);
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      // Unsigned Gradient Noise 1d
      float ugnoise1d(float position)
      {
	 return (0.5f - 0.5f * sgnoise1d(position));
      }

      // Unsigned Gradient Noise 2d
      float ugnoise2d(float2 position)
      {
	 return (0.5f - 0.5f * sgnoise2d(position));
      }

      // Unsigned Gradient Noise 3d
      float ugnoise3d(float4 position)
      {
	 return (0.5f - 0.5f * sgnoise3d(position));
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      uchar4
      tonemap(float4 color)
      {
	 uchar4 result = convert_uchar4_sat_rte(color * 255.0f);
	 return result;
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      float monofractal2d(
	 float2 position, 
	 float frequency,
	 float lacunarity, 
	 float increment, 
	 float octaves)
      {
	 int i = 0;
	 float fi = 0.0f;
	 float remainder = 0.0f;	
	 float sample = 0.0f;	
	 float value = 0.0f;
	 int iterations = (int)octaves;
	 
	 for (i = 0; i < iterations; i++)
	 {
	    fi = (float)i;
	    sample = sgnoise2d(position * frequency);
	    sample *= pow( lacunarity, -fi * increment );
	    value += sample;
	    frequency *= lacunarity;
	 }
	 
	 remainder = octaves - (float)iterations;
	 if ( remainder > 0.0f )
	 {
	    sample = remainder * sgnoise2d(position * frequency);
	    sample *= pow( lacunarity, -fi * increment );
	    value += sample;
	 }
	 
	 return value;	
      }

      float multifractal2d(
	 float2 position, 
	 float frequency,
	 float lacunarity, 
	 float increment, 
	 float octaves)
      {
	 int i = 0;
	 float fi = 0.0f;
	 float remainder = 0.0f;	
	 float sample = 0.0f;	
	 float value = 1.0f;
	 int iterations = (int)octaves;
	 
	 for (i = 0; i < iterations; i++)
	 {
	    fi = (float)i;
	    sample = sgnoise2d(position * frequency) + 1.0f;
	    sample *= pow( lacunarity, -fi * increment );
	    value *= sample;
	    frequency *= lacunarity;
	 }
	 
	 remainder = octaves - (float)iterations;
	 if ( remainder > 0.0f )
	 {
	    sample = remainder * (sgnoise2d(position * frequency) + 1.0f);
	    sample *= pow( lacunarity, -fi * increment );
	    value *= sample;
	 }
	 
	 return value;	
      }

      float turbulence2d(
	 float2 position, 
	 float frequency,
	 float lacunarity, 
	 float increment, 
	 float octaves)
      {
	 int i = 0;
	 float fi = 0.0f;
	 float remainder = 0.0f;	
	 float sample = 0.0f;	
	 float value = 0.0f;
	 int iterations = (int)octaves;
	 
	 for (i = 0; i < iterations; i++)
	 {
	    fi = (float)i;
	    sample = sgnoise2d(position * frequency);
	    sample *= pow( lacunarity, -fi * increment );
	    value += fabs(sample);
	    frequency *= lacunarity;
	 }
	 
	 remainder = octaves - (float)iterations;
	 if ( remainder > 0.0f )
	 {
	    sample = remainder * sgnoise2d(position * frequency);
	    sample *= pow( lacunarity, -fi * increment );
	    value += fabs(sample);
	 }
	 
	 return value;	
      }

      float ridgedmultifractal2d(
	 float2 position, 
	 float frequency,
	 float lacunarity, 
	 float increment, 
	 float octaves)
      {
	 int i = 0;
	 float fi = 0.0f;
	 float remainder = 0.0f;	
	 float sample = 0.0f;	
	 float value = 0.0f;
	 int iterations = (int)octaves;

	 float threshold = 0.5f;
	 float offset = 1.0f;
	 float weight = 1.0f;

	 float signal = fabs( sgnoise2d(position * frequency) );
	 signal = offset - signal;
	 signal *= signal;
	 value = signal;

	 for ( i = 0; i < iterations; i++ )
	 {
	    frequency *= lacunarity;
	    weight = clamp( signal * threshold, 0.0f, 1.0f );	
	    signal = fabs( sgnoise2d(position * frequency) );
	    signal = offset - signal;
	    signal *= signal;
	    signal *= weight;
	    value += signal * pow( lacunarity, -fi * increment );

	 }
	 return value;
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      float multifractal3d(
	 float4 position, 
	 float frequency,
	 float lacunarity, 
	 float increment, 
	 float octaves)
      {
	 int i = 0;
	 float fi = 0.0f;
	 float remainder = 0.0f;	
	 float sample = 0.0f;	
	 float value = 1.0f;
	 int iterations = (int)octaves;
	 
	 for (i = 0; i < iterations; i++)
	 {
	    fi = (float)i;
	    sample = (1.0f - 2.0f * sgnoise3d(position * frequency)) + 1.0f;
	    sample *= pow( lacunarity, -fi * increment );
	    value *= sample;
	    frequency *= lacunarity;
	 }
	 
	 remainder = octaves - (float)iterations;
	 if ( remainder > 0.0f )
	 {
	    sample = remainder * (1.0f - 2.0f * sgnoise3d(position * frequency)) + 1.0f;
	    sample *= pow( lacunarity, -fi * increment );
	    value *= sample;
	 }
	 
	 return value;	
      }

      float ridgedmultifractal3d(
	 float4 position, 
	 float frequency,
	 float lacunarity, 
	 float increment, 
	 float octaves)
      {
	 int i = 0;
	 float fi = 0.0f;
	 float remainder = 0.0f;	
	 float sample = 0.0f;	
	 float value = 0.0f;
	 int iterations = (int)octaves;

	 float threshold = 0.5f;
	 float offset = 1.0f;
	 float weight = 1.0f;

	 float signal = fabs( (1.0f - 2.0f * sgnoise3d(position * frequency)) );
	 signal = offset - signal;
	 signal *= signal;
	 value = signal;

	 for ( i = 0; i < iterations; i++ )
	 {
	    frequency *= lacunarity;
	    weight = clamp( signal * threshold, 0.0f, 1.0f );	
	    signal = fabs( (1.0f - 2.0f * sgnoise3d(position * frequency)) );
	    signal = offset - signal;
	    signal *= signal;
	    signal *= weight;
	    value += signal * pow( lacunarity, -fi * increment );

	 }
	 return value;
      }

      float turbulence3d(
	 float4 position, 
	 float frequency,
	 float lacunarity, 
	 float increment, 
	 float octaves)
      {
	 int i = 0;
	 float fi = 0.0f;
	 float remainder = 0.0f;	
	 float sample = 0.0f;	
	 float value = 0.0f;
	 int iterations = (int)octaves;
	 
	 for (i = 0; i < iterations; i++)
	 {
	    fi = (float)i;
	    sample = (1.0f - 2.0f * sgnoise3d(position * frequency));
	    sample *= pow( lacunarity, -fi * increment );
	    value += fabs(sample);
	    frequency *= lacunarity;
	 }
	 
	 remainder = octaves - (float)iterations;
	 if ( remainder > 0.0f )
	 {
	    sample = remainder * (1.0f - 2.0f * sgnoise3d(position * frequency));
	    sample *= pow( lacunarity, -fi * increment );
	    value += fabs(sample);
	 }
	 
	 return value;	
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      #if USE_IMAGES_FOR_RESULTS

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      __kernel void 
      GradientNoiseImage2d(	
	 write_only image2d_t output,
	 const float2 bias, 
	 const float2 scale,
	 const float amplitude) 
      {
	 int2 coord = (int2)(get_global_id(0), get_global_id(1));

	 int2 size = (int2)(get_global_size(0), get_global_size(1));

	 float2 position = (float2)(coord.x / (float)size.x, 
				    coord.y / (float)size.y);
	 
	 float2 sample = (position + bias) * scale;
	 
	 float value = ugnoise2d(sample);
	 
	 float4 color = (float4)(value, value, value, 1.0f) * amplitude;
	 color.w = 1.0f;
	 
	 write_imagef(output, coord, color);
      }

      __kernel void 
      MonoFractalImage2d(
	 write_only image2d_t output,
	 const float2 bias, 
	 const float2 scale,
	 const float lacunarity, 
	 const float increment, 
	 const float octaves,	
	 const float amplitude)
      {
	 int2 coord = (int2)(get_global_id(0), get_global_id(1));

	 int2 size = (int2)(get_global_size(0), get_global_size(1));

	 float2 position = (float2)(coord.x / (float)size.x, 
				    coord.y / (float)size.y);
	 
	 float2 sample = (position + bias);
	 
	 float value = monofractal2d(sample, scale.x, lacunarity, increment, octaves);

	 float4 color = (float4)(value, value, value, 1.0f) * amplitude;
	 color.w = 1.0f;
	 
	 write_imagef(output, coord, color);
      }

      __kernel void 
      TurbulenceImage2d(
	 write_only image2d_t output,
	 const float2 bias, 
	 const float2 scale,
	 const float lacunarity, 
	 const float increment, 
	 const float octaves,	
	 const float amplitude) 
      {
	 int2 coord = (int2)(get_global_id(0), get_global_id(1));

	 int2 size = (int2)(get_global_size(0), get_global_size(1));

	 float2 position = (float2)(coord.x / (float)size.x, 
				    coord.y / (float)size.y);
	 
	 float2 sample = (position + bias);

	 float value = turbulence2d(sample, scale.x, lacunarity, increment, octaves);

	 float4 color = (float4)(value, value, value, 1.0f) * amplitude;
	 color.w = 1.0f;

	 write_imagef(output, coord, color);
      }

      __kernel void 
      RidgedMultiFractalImage2d(	
	 write_only image2d_t output,
	 const float2 bias, 
	 const float2 scale,
	 const float lacunarity, 
	 const float increment, 
	 const float octaves,	
	 const float amplitude) 
      {
	 int2 coord = (int2)(get_global_id(0), get_global_id(1));

	 int2 size = (int2)(get_global_size(0), get_global_size(1));

	 float2 position = (float2)(coord.x / (float)size.x, 
				    coord.y / (float)size.y);
	 
	 float2 sample = (position + bias);

	 float value = ridgedmultifractal2d(sample, scale.x, lacunarity, increment, octaves);

	 float4 color = (float4)(value, value, value, 1.0f) * amplitude;
	 color.w = 1.0f;

	 write_imagef(output, coord, color);
      }

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      #endif // USE_IMAGES_FOR_RESULTS

      ////////////////////////////////////////////////////////////////////////////////////////////////////

      __kernel void 
      GradientNoiseArray2d(	
	 __global uchar4 *output,
	 const float2 bias, 
	 const float2 scale,
	 const float amplitude) 
      {
	 int2 coord = (int2)(get_global_id(0), get_global_id(1));

	 int2 size = (int2)(get_global_size(0), get_global_size(1));

	 float2 position = (float2)(coord.x / (float)size.x, coord.y / (float)size.y);
	 
	 float2 sample = (position + bias) * scale;
	 
	 float value = ugnoise2d(sample);
	 
	 float4 result = (float4)(value, value, value, 1.0f) * amplitude;

	 uint index = coord.y * size.x + coord.x;
	 output[index] = tonemap(result);
      }

      __kernel void 
      MonoFractalArray2d(
	 __global uchar4 *output,
	 const float2 bias, 
	 const float2 scale,
	 const float lacunarity, 
	 const float increment, 
	 const float octaves,	
	 const float amplitude)
      {
	 int2 coord = (int2)(get_global_id(0), get_global_id(1));

	 int2 size = (int2)(get_global_size(0), get_global_size(1));

	 float2 position = (float2)(coord.x / (float)size.x, 
				    coord.y / (float)size.y);
	 
	 float2 sample = (position + bias);
	 
	 float value = monofractal2d(sample, scale.x, lacunarity, increment, octaves);

	 float4 result = (float4)(value, value, value, 1.0f) * amplitude;

	 uint index = coord.y * size.x + coord.x;
	 output[index] = tonemap(result);
      }

      __kernel void 
      TurbulenceArray2d(
	 __global uchar4 *output,
	 const float2 bias, 
	 const float2 scale,
	 const float lacunarity, 
	 const float increment, 
	 const float octaves,	
	 const float amplitude) 
      {
	 int2 coord = (int2)(get_global_id(0), get_global_id(1));

	 int2 size = (int2)(get_global_size(0), get_global_size(1));

	 float2 position = (float2)(coord.x / (float)size.x, coord.y / (float)size.y);
	 
	 float2 sample = (position + bias);

	 float value = turbulence2d(sample, scale.x, lacunarity, increment, octaves);

	 float4 result = (float4)(value, value, value, 1.0f) * amplitude;

	 uint index = coord.y * size.x + coord.x;
	 output[index] = tonemap(result);
      }

      __kernel void 
      RidgedMultiFractalArray2d(	
	 __global uchar4 *output,
	 const float2 bias, 
	 const float2 scale,
	 const float lacunarity, 
	 const float increment, 
	 const float octaves,	
	 const float amplitude) 
      {
	 int2 coord = (int2)(get_global_id(0), get_global_id(1));

	 int2 size = (int2)(get_global_size(0), get_global_size(1));

	 float2 position = (float2)(coord.x / (float)size.x, 
				    coord.y / (float)size.y);
	 
	 float2 sample = (position + bias);

	 float value = ridgedmultifractal2d(sample, scale.x, lacunarity, increment, octaves);

	 float4 result = (float4)(value, value, value, 1.0f) * amplitude;

	 uint index = coord.y * size.x + coord.x;
	 output[index] = tonemap(result);
      }
]==]

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
   assert( glfw.glfwInit() )
   local window = glfw.glfwOpenWindow( width, height, glfw.GLFW_WINDOWED, "Spinning Triangle", nil)
   assert( window )
   glfw.glfwEnable(window, glfw.GLFW_STICKY_KEYS);
   glfw.glfwSwapInterval(1);

   local MouseX, MouseY

   while glfw.glfwIsWindow(window) and glfw.glfwGetKey(window, glfw.GLFW_KEY_ESCAPE) ~= glfw.GLFW_PRESS 
   do
      local x, y = ffi.new( "int[1]" ), ffi.new( "int[1]" )
      glfw.glfwGetMousePos(window, x, y)
      x, y = x[0], y[0]

      local leftButton  = glfw.glfwGetMouseButton( window, glfw.GLFW_MOUSE_BUTTON_LEFT )
      local rightButton = glfw.glfwGetMouseButton( window, glfw.GLFW_MOUSE_BUTTON_RIGHT )
      local middleButton = glfw.glfwGetMouseButton( window, glfw.GLFW_MOUSE_BUTTON_MIDDLE )

      local width, height = ffi.new( "int[1]" ), ffi.new( "int[1]" )
      glfw.glfwGetWindowSize(window, width, height);
      width, height = width[0], height[0]
      if height < 1 then
	 height = 1
      end

      gl.glViewport(0, 0, width, height);
      gl.glClearColor(0, 0, 0, 0);
      gl.glClear(gl.GL_COLOR_BUFFER_BIT);

      gl.glMatrixMode(gl.GL_PROJECTION);
      gl.glLoadIdentity();
      glu.gluPerspective(65, width / height, 1, 100);
      
      gl.glMatrixMode( gl.GL_MODELVIEW );
      gl.glLoadIdentity();
      glu.gluLookAt(
	 0,  1, 0,   -- Eye-position
	 0, 20, 0,   -- View-point
	 0,  0, 1    -- Up Vector
      );
      
      gl.glTranslatef(0, 14, 0);
      gl.glRotatef(0.3 * x + t * 100, 0, 0, 1);
      
      gl.glBegin(gl.GL_TRIANGLES);
      gl.glColor3f(1, 0, 0);
      gl.glVertex3f(-5, 0, -4);
      gl.glColor3f(0, 1, 0);
      gl.glVertex3f(5, 0, -4);
      gl.glColor3f(0, 0, 1);
      gl.glVertex3f(0, 0, 6);
      gl.glEnd();
      
      glfw.glfwSwapBuffers();
      glfw.glfwPollEvents();
   end
   glfw.glfwTerminate();
end

main()

