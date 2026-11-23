// sharpen_lite_msc.glsl v2.1 - for MPV-SW-Capture - By TyRaS-SW
// Ultra-light sharpen made for low latency: one fragment pass, 5 reads of the
// luma plane only (no chroma, no compute shader, no pow(), no loops).
//
// It hooks LUMA, so only one channel is touched and colors do not shift.
// In GPU scaling mode it runs before the upscale, on about 4 times fewer
// pixels than a post-scaling shader. In CPU scaling mode it runs on the
// already scaled frame. LUMA hooks only run on YUV video, which is what
// capture cards normally give.
//
// Tuning guide (change one value at a time):
//   Still looks gritty / old ..... lower STRENGTH (1.2), raise NOISE_LO / NOISE_HI (0.008 / 0.04)
//   Effect too weak .............. raise STRENGTH (2.0)
//   Halos or dark outlines ....... lower OVERSHOOT (0.05)
//   HUD / thin lines too harsh ... RADIUS 1.5, or EDGE_DAMP 1.5
//   Wide edges soft / upscaled ... RADIUS 2.5

//!PARAM STRENGTH
//!DESC Sharpening strength (0 = off, 1.0 subtle, 1.6 default, 3.0 strong)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 5.0
1.6

//!PARAM RADIUS
//!DESC Distance of the sampled neighbours in pixels (1.0 = direct neighbours)
//!TYPE float
//!MINIMUM 0.5
//!MAXIMUM 3.0
2.0

//!PARAM OVERSHOOT
//!DESC Allowed overshoot past the local min/max (0 = no halos, 0.05 light, 0.08 default, 0.15 strong)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 0.5
0.08

//!PARAM EDGE_DAMP
//!DESC Less gain where local contrast is already high (0 = off, 0.5 strong look, 1.0 default, 1.5 to 2.0 softer HUD)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 4.0
1.0

//!PARAM NOISE_LO
//!DESC Noise gate start: differences below this are ignored (0.004 is about 1 level of 255)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 0.05
0.006

//!PARAM NOISE_HI
//!DESC Noise gate end: full effect from this difference up (must be greater than NOISE_LO)
//!TYPE float
//!MINIMUM 0.001
//!MAXIMUM 0.1
0.030

//!HOOK LUMA
//!BIND HOOKED
//!DESC msc sharpen lite v2.1
//!WHEN STRENGTH

// Maximum luma change per pixel (luma plane units, 0 to 1).
#define LIMIT 0.25

vec4 hook() {
	// Luma plane: the value is in the x component
	float c = HOOKED_texOff(vec2(0.0)).x;
	float n = HOOKED_texOff(vec2(0.0, -RADIUS)).x;
	float s = HOOKED_texOff(vec2(0.0,  RADIUS)).x;
	float w = HOOKED_texOff(vec2(-RADIUS, 0.0)).x;
	float e = HOOKED_texOff(vec2( RADIUS, 0.0)).x;

	// Pixel minus the average of its 4 neighbours
	float d = c - 0.25 * (n + s + w + e);

	// Local range: bounds the result and damps strong edges
	float lo  = min(min(min(c, n), min(s, w)), e);
	float hi  = max(max(max(c, n), max(s, w)), e);
	float rng = hi - lo;

	// Noise gate, gain damped by local contrast, and a maximum change
	float delta = clamp(d * smoothstep(NOISE_LO, NOISE_HI, abs(d)) * STRENGTH
	                      / (1.0 + EDGE_DAMP * rng), -LIMIT, LIMIT);

	// Stay inside the local range plus the small overshoot margin
	float ov = OVERSHOOT * rng;
	return vec4(clamp(c + delta, lo - ov, hi + ov), 0.0, 0.0, 1.0);
}
