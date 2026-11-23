// aa_lite_msc4.glsl v4.2 - for MPV-SW-Capture - By TyRaS-SW
// Stronger anti-aliasing for STAIR STEPS OF SEVERAL PIXELS (3-4 px, typical of
// a console image scaled up to the capture size). 17 reads on the luma plane.
//
// Tuning guide (change one value at a time):
//   Steps still visible, long ..... raise SPAN (up to 12)
//   Steps still visible, 4+ px .... raise SCALE (3.0, 3.5)
//   Low contrast edges jagged ..... lower THRESHOLD (0.01)
//   Image looks soft / waxy ....... raise THRESHOLD (0.05), lower SPAN (5) or STRENGTH (0.7)
//   Corners / thin details round .. lower SPAN (4-5) or lower SCALE (2.0)
//   Text / HUD still distorted .... lower MAXEDGE (0.10)
//   Strong game edges not smoothed  raise MAXEDGE (0.25; 1.0 = no protection,
//   text gets distorted)

//!PARAM STRENGTH
//!DESC Blend amount along the edge (0 = off, 1 = full)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
1.0

//!PARAM THRESHOLD
//!DESC Minimum edge gradient to act on, full effect at twice this value (0.02 is about 5 levels of 255)
//!TYPE float
//!MINIMUM 0.005
//!MAXIMUM 0.5
0.02

//!PARAM SPAN
//!DESC Reach of the blend along the edge on each side, in pixels
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 12.0
8.0

//!PARAM SCALE
//!DESC Distance in pixels at which the edge direction is measured; about the length of one stair step
//!TYPE float
//!MINIMUM 1.0
//!MAXIMUM 6.0
2.5

//!PARAM MAXEDGE
//!DESC Edges with a gradient above this are left alone (protects text / HUD); fades out at 1.7x this value
//!TYPE float
//!MINIMUM 0.1
//!MAXIMUM 1.0
0.15

//!HOOK LUMA
//!BIND HOOKED
//!DESC msc aa lite v4.2
//!WHEN STRENGTH

vec4 hook() {
	float c = HOOKED_texOff(vec2(0.0)).x;

	// Sobel gradient at SCALE pixels (8 reads), averaged to luma per pixel
	float R = SCALE;
	float nw = HOOKED_texOff(vec2(-R, -R)).x;
	float nn = HOOKED_texOff(vec2( 0.0, -R)).x;
	float ne = HOOKED_texOff(vec2( R, -R)).x;
	float ww = HOOKED_texOff(vec2(-R,  0.0)).x;
	float ee = HOOKED_texOff(vec2( R,  0.0)).x;
	float sw = HOOKED_texOff(vec2(-R,  R)).x;
	float ss = HOOKED_texOff(vec2( 0.0,  R)).x;
	float se = HOOKED_texOff(vec2( R,  R)).x;

	float gx = ((ne + 2.0 * ee + se) - (nw + 2.0 * ww + sw)) * 0.25;
	float gy = ((sw + 2.0 * ss + se) - (nw + 2.0 * nn + ne)) * 0.25;
	float mag = length(vec2(gx, gy));

	float gate = smoothstep(THRESHOLD, 2.0 * THRESHOLD, mag)
	           * (1.0 - smoothstep(MAXEDGE, 1.7 * MAXEDGE, mag));
	if (gate <= 0.0)
		return vec4(c, 0.0, 0.0, 1.0);

	// Edge tangent = perpendicular to the gradient
	vec2 t = vec2(-gy, gx) / max(mag, 1e-6);

	// Gaussian average along the tangent: centre + 4 samples on each side
	float acc = c;
	float wsum = 1.0;
	for (int i = 1; i <= 4; i++) {
		float w = exp(-float(i * i) * 0.125);   // sigma = 2 samples
		vec2 d = t * (SPAN * float(i) * 0.25);
		acc  += w * (HOOKED_texOff( d).x + HOOKED_texOff(-d).x);
		wsum += 2.0 * w;
	}
	float o = acc / wsum;

	return vec4(c + (o - c) * STRENGTH * gate, 0.0, 0.0, 1.0);
}
