// LICENSE
// =======
// Copyright (c) 2017-2019 Advanced Micro Devices, Inc. All rights reserved.
// -------
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// -------
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// -------
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// FidelityFX Contrast Adaptive Sharpening 1.2 by AMD
// ported to mpv by agyild

// Changelog
// 2022
// - Optimized texture lookups for OpenGL 4.0+, DirectX 10+, and OpenGL ES 3.1+
// - Changed rcp + mul operations to div for better clarity when CAS_GO_SLOWER is set to 1, since the compiler should automatically
// optimize those instructions anyway.
// - Made it directly operate on LUMA plane, since the original shader was operating on LUMA by deriving it from RGB. This should
// cause a major increase in performance, especially on OpenGL 4.0+ renderers (4 texture lookups vs. 16)
// - Removed transparency preservation mechanism since the alpha channel is a separate source plan than LUMA
// - Removed final blending between the original and the sharpened pixels since it was redundant
// 
// 2026-11-17
// - Replaced the hardcoded TRC functions with libplacebo's builtin linearize/delinearize functions
// - Added tunable parameter support
// - SHARPENING is renamed as Sharpness to follow the same convention as the other shaders (i.e., NIS, FSR, SGSR)
// - CAS_GO_SLOWER parameter is renamed as UsePreciseMath as per FidelityFX SDK v1.1.4
// - Removed the !WHEN constraint which should always apply the sharpen effect, not just for non-scaled playback
// - Replaced per-pixel peak division with a precomputed reciprocal multiply (invPeak)
// - Replaced HOOKED_texOff calls with integer texelFetch lookups on HOOKED_raw and factored out shared HOOKED_gather offsets
// - Added //!COMPONENTS 1 to both passes and eliminated dead channel writes in the linearization pass
// - Changed UsePreciseMath default from 0 to 1 for better precision and SFU utilization on modern GPUs

// User variables

//!PARAM Sharpness
//!DESC Adjusts the range the shader adapts to high contrast (0 is not all the way off).  Higher values = more high contrast sharpening.
//!TYPE CONSTANT float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM BetterDiagonals
//!DESC If set to 0, drops certain math and texture lookup operations for better performance. This is only useful on pre-OpenGL 4.0 renderers and there is no need to disable it otherwise.
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM UsePreciseMath
//!DESC If set to 1, disables the use of optimized approximate transcendental functions which might slightly increase accuracy in exchange of performance.
//!TYPE DEFINE
//!MINIMUM 0
//!MAXIMUM 1
1

//!HOOK LUMA
//!BIND HOOKED
//!DESC FidelityFX Contrast Adaptive Sharpening (CAS) v1.2 (Linearization pass)
//!COMPONENTS 1

// libplacebo's linearize() builtin converts the video's tagged transfer characteristics to linear light.

vec4 hook() {
	return vec4(linearize(HOOKED_tex(HOOKED_pos)).r, 0.0, 0.0, 1.0);
}

//!HOOK LUMA
//!BIND HOOKED
//!DESC FidelityFX Contrast Adaptive Sharpening (CAS) v1.2 (Sharpening pass)
//!COMPONENTS 1

// Shader code

#if (UsePreciseMath == 0)

float APrxLoSqrtF1(float a) {
	return uintBitsToFloat((floatBitsToUint(a) >> uint(1)) + uint(0x1fbc4639));
}

float APrxLoRcpF1(float a) {
	return uintBitsToFloat(uint(0x7ef07ebb) - floatBitsToUint(a));
}

float APrxMedRcpF1(float a) {
	float b = uintBitsToFloat(uint(0x7ef19fff) - floatBitsToUint(a));
	return b * (-b * a + float(2.0));
}

#endif

vec4 hook()
{
	// fetch a 3x3 neighborhood around the pixel 'e',
	//  a b c
	//  d(e)f
	//  g h i

#if (defined(HOOKED_gather) && (__VERSION__ >= 400 || (GL_ES && __VERSION__ >= 310)))
	vec2 half_pt = 0.5 * HOOKED_pt;
	vec4 efhi = HOOKED_gather(HOOKED_pos + half_pt, 0);

	float e = efhi.w;
	float f = efhi.z;
	float h = efhi.x;

	vec3 abd = HOOKED_gather(HOOKED_pos - half_pt, 0).wzx;
	float b = abd.y;
	float d = abd.z;

	#if (BetterDiagonals == 1)
		float a = abd.x;
		float i = efhi.y;

		ivec2 sp = ivec2(HOOKED_pos * HOOKED_size);
		float c = texelFetch(HOOKED_raw, sp + ivec2( 1, -1), 0).r * HOOKED_mul;
		float g = texelFetch(HOOKED_raw, sp + ivec2(-1,  1), 0).r * HOOKED_mul;
	#endif
#else
	ivec2 sp = ivec2(HOOKED_pos * HOOKED_size);

	float e = texelFetch(HOOKED_raw, sp                , 0).r * HOOKED_mul;
	float f = texelFetch(HOOKED_raw, sp + ivec2( 1,  0), 0).r * HOOKED_mul;
	float h = texelFetch(HOOKED_raw, sp + ivec2( 0,  1), 0).r * HOOKED_mul;
	float b = texelFetch(HOOKED_raw, sp + ivec2( 0, -1), 0).r * HOOKED_mul;
	float d = texelFetch(HOOKED_raw, sp + ivec2(-1,  0), 0).r * HOOKED_mul;

	#if (BetterDiagonals == 1)
		float a = texelFetch(HOOKED_raw, sp + ivec2(-1, -1), 0).r * HOOKED_mul;
		float c = texelFetch(HOOKED_raw, sp + ivec2( 1, -1), 0).r * HOOKED_mul;
		float g = texelFetch(HOOKED_raw, sp + ivec2(-1,  1), 0).r * HOOKED_mul;
		float i = texelFetch(HOOKED_raw, sp + ivec2( 1,  1), 0).r * HOOKED_mul;
	#endif
#endif

	// Soft min and max.
	//  a b c			b
	//  d e f * 0.5	+ d e f * 0.5
	//  g h i			h
	// These are 2.0x bigger (factored out the extra multiply).

	float mnL = min(min(min(d, e), min(f, b)), h);
	float mxL = max(max(max(d, e), max(f, b)), h);
#if (BetterDiagonals == 1)
	float mnL2 = min(mnL, min(min(a, c), min(g, i)));
	mnL += mnL2;

	float mxL2 = max(mxL, max(max(a, c), max(g, i)));
	mxL += mxL2;
#endif

	// Smooth minimum distance to signal limit divided by smooth max.
	const float bdval = bool(BetterDiagonals) ? 2.0 : 1.0;
#if (UsePreciseMath == 1)
	float ampL = clamp(min(mnL, bdval - mxL) / mxL, 0.0, 1.0);
#else
	float ampL = clamp(min(mnL, bdval - mxL) * APrxLoRcpF1(mxL), 0.0, 1.0);
#endif

	// Shaping amount of sharpening.
#if (UsePreciseMath == 1)
	ampL = sqrt(ampL);
#else
	ampL = APrxLoSqrtF1(ampL);
#endif

	// Filter shape.
	//  0 w 0
	//  w 1 w
	//  0 w 0

	const float invPeak = -1.0 / mix(8.0, 5.0, clamp(Sharpness, 0.0, 1.0));
	float wL = ampL * invPeak;

	// Filter.
	// Using green coef only
	float Weight = 1.0 + 4.0 * wL;
	vec4 pix = vec4(0.0, 0.0, 0.0, 1.0);
	pix.r = ((b + d + f + h) * wL) + e;
#if (UsePreciseMath == 1)
	pix.r /= Weight;
#else
	pix.r *= APrxMedRcpF1(Weight);
#endif
	pix.r = delinearize(pix).r;

	return pix;
}