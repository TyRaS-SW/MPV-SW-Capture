// This file is inspired by a Broken LCD TV look. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)

//!HOOK MAIN
//!BIND MAIN
//!DESC Simple CRT Universal (scanlines + mask + warp)

// Basic parameters
#define CRT_STRENGTH   0.65   // Global effect intensity (0–1.2)
#define SCAN_STRENGTH  0.45   // Horizontal scanline depth
#define MASK_STRENGTH  1.1    // Subpixel mask intensity
#define BLOOM_STRENGTH 0.04   // Soft local bloom
#define CURVE_AMOUNT   0.0    // Screen curvature
#define EDGE_DARKEN    0.0    // Edge darkening

// Soft Trinitron-style curvature
vec2 crt_warp(vec2 coord)
{
    coord = coord * 2.0 - 1.0;
    float xr = coord.x * sqrt(1.0 - CURVE_AMOUNT * coord.y * coord.y);
    float yr = coord.y * sqrt(1.0 - CURVE_AMOUNT * coord.x * coord.x);
    coord = vec2(xr, yr);
    return coord * 0.5 + 0.5;
}

// RGB subpixel triad mask
vec3 rgb_mask(vec2 coord)
{
    // Intensity pattern, same value in R,G,B ⇒ no color tint
    float phase  = fract(coord.x * MAIN_size.x / 2.0);
    float stripe = step(0.25, phase) * step(phase, 0.75); // central stripe

    float m = mix(1.0, 0.2, stripe); // slightly darker in the stripe
    return vec3(mix(1.0, m, MASK_STRENGTH));
}

// Smooth per-line scanline weight
float scan_weight(vec2 coord)
{
    float line = coord.y * MAIN_size.y;
    float dist = abs(fract(line) - 0.5);
    float w = 1.0 - SCAN_STRENGTH * smoothstep(0.0, 0.5, dist);
    return w;
}

// Very cheap local bloom (cross-shaped samples)
vec3 local_bloom(vec2 coord)
{
    vec2 px = 1.0 / MAIN_size.xy;
    vec3 c  = MAIN_tex(coord).rgb;
    vec3 cx = MAIN_tex(coord + vec2(px.x, 0.0)).rgb +
              MAIN_tex(coord - vec2(px.x, 0.0)).rgb;
    vec3 cy = MAIN_tex(coord + vec2(0.0, px.y)).rgb +
              MAIN_tex(coord - vec2(0.0, px.y)).rgb;
    vec3 neigh = (cx + cy) * 0.25;
    return mix(c, neigh, BLOOM_STRENGTH);
}

// Corner darkening
float vignette(vec2 coord)
{
    vec2 pos = coord * 2.0 - 1.0;
    float r2 = dot(pos, pos);
    float v = 1.0 - EDGE_DARKEN * smoothstep(0.6, 1.1, r2);
    return v;
}

vec4 hook()
{
    // Curvature
    vec2 coord = crt_warp(MAIN_pos);

    // Outside screen → black
    if (coord.x < 0.0 || coord.x > 1.0 || coord.y < 0.0 || coord.y > 1.0)
        return vec4(0.0);

    // Local bloom
    vec3 color = local_bloom(coord);

    // Scanlines
    float sw = scan_weight(coord);
    color *= sw;

    // RGB mask
    vec3 mask = rgb_mask(coord);
    color *= mask;

    // Slight gamma compression for a more CRT-like look
    color = pow(color, vec3(0.90));

    // Vignette / edges
    color *= vignette(MAIN_pos);

    // Mix with original image if you want to soften the effect
    vec3 base = MAIN_tex(MAIN_pos).rgb;
    color = mix(base, color, CRT_STRENGTH);

    return vec4(color, 1.0);
}