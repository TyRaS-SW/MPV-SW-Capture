// This file is inspired by a CRT Vertical Slot Mask look. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)

//!HOOK MAIN
//!BIND MAIN
//!DESC CRT Vertical Slot Mask

// Basic parameters
#define CRT_STRENGTH   0.8   // Global effect strength (0–1.2)
#define SCAN_STRENGTH  0.10   // Horizontal scanline depth
#define MASK_STRENGTH  0.45   // Vertical mask intensity
#define BLOOM_STRENGTH 0.0    // Local soft bloom
#define CURVE_AMOUNT   0.0    // Screen curvature
#define EDGE_DARKEN    0.0    // Edge darkening

// Soft Trinitron-like curvature
vec2 crt_warp(vec2 coord)
{
    coord = coord * 2.0 - 1.0;
    float xr = coord.x * sqrt(1.0 - CURVE_AMOUNT * coord.y * coord.y);
    float yr = coord.y * sqrt(1.0 - CURVE_AMOUNT * coord.x * coord.x);
    coord = vec2(xr, yr);
    return coord * 0.5 + 0.5;
}

// Vertical brightness mask
vec3 rgb_mask(vec2 coord)
{
    float phase  = fract(MAIN_pos.x * 260.0);
    float stripe = smoothstep(0.20, 0.50, phase) - smoothstep(0.50, 0.80, phase);

    // 1.0 ↔ 0.6 brightness in the central band
    float m = mix(1.0, 0.6, stripe);
    float factor = mix(1.0, m, MASK_STRENGTH);
    return vec3(factor);
}

// Slot mask 2D (holes in a grid)
vec3 slot_mask(vec2 coord)
{
    float freqX = 420.0;
    float freqY = 320.0;

    vec2 cell = vec2(
        fract(MAIN_pos.x * freqX),
        fract(MAIN_pos.y * freqY)
    );

    float rx = 0.28;
    float ry = 0.40;

    float nx = (cell.x - 0.5) / rx;
    float ny = (cell.y - 0.5) / ry;
    float d2 = nx*nx + ny*ny;

    float slot = smoothstep(1.2, 1.0, d2);

    float m = mix(1.0, 0.4, 1.0 - slot);
    float factor = mix(1.0, m, MASK_STRENGTH);

    return vec3(factor);
}

// Smooth vertical scanlines (per line)
float scan_weight(vec2 coord)
{
    float line = coord.y * MAIN_size.y;
    float dist = abs(fract(line) - 0.5);
    float w = 1.0 - SCAN_STRENGTH * smoothstep(0.0, 0.5, dist);
    return w;
}

// Very cheap local bloom (cross samples)
vec3 local_bloom(vec2 coord)
{
    vec2 px = 1.0 / MAIN_size.xy;

    vec3 c  = MAIN_tex(coord).rgb;
    vec3 l  = MAIN_tex(coord - vec2(px.x, 0.0)).rgb;
    vec3 r  = MAIN_tex(coord + vec2(px.x, 0.0)).rgb;

    vec3 horiz = (l + r + c) / 3.0;
    // Minimal blend to avoid washing out the image
    return mix(c, horiz, 0.10); // 0.10 = bloom strength
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
    vec2 coord = crt_warp(MAIN_pos);
    if (coord.x < 0.0 || coord.x > 1.0 || coord.y < 0.0 || coord.y > 1.0)
        return vec4(0.0);

    vec3 color = local_bloom(coord);
    float sw   = scan_weight(coord);
    color *= sw;

    // Para aperture grille:
    // vec3 mask = rgb_mask(coord);

    // Para slot mask:
    vec3 mask = slot_mask(coord);
    color *= mask;

    vec3 base = MAIN_tex(MAIN_pos).rgb;
    color = mix(base, color, CRT_STRENGTH);

    return vec4(color, 1.0);
}