// This file is inspired by a Broken LCD TV look. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//
// FIX: Changed hook to MAIN instead of OUTPUT to be compatible with bezel shields.
// Now uses MAIN_size/MAIN_pos/MAIN_tex, and applies before bezel overlays.

//!HOOK MAIN
//!BIND MAIN
//!DESC Simple CRT Universal (scanlines + mask + warp)

#define CRT_STRENGTH   0.65
#define SCAN_STRENGTH  0.45
#define MASK_STRENGTH  1.1
#define BLOOM_STRENGTH 0.04
#define CURVE_AMOUNT   0.0
#define EDGE_DARKEN    0.0

#define FINE_TUNE 1.0

const float REF_WIDTH  = 1920.0;
const float REF_HEIGHT = 1080.0;

vec2 crt_warp(vec2 coord)
{
    coord = coord * 2.0 - 1.0;
    float xr = coord.x * sqrt(1.0 - CURVE_AMOUNT * coord.y * coord.y);
    float yr = coord.y * sqrt(1.0 - CURVE_AMOUNT * coord.x * coord.x);
    coord = vec2(xr, yr);
    return coord * 0.5 + 0.5;
}

vec3 rgb_mask(vec2 coord)
{
    float mask_freq = (MAIN_size.x * 0.5) * FINE_TUNE;
    float phase = fract(coord.x * mask_freq);

    float start = 0.25;
    float end   = 0.75;

    float stripe = step(start, phase) * step(phase, end);
    float m = mix(1.0, 0.2, stripe);
    return vec3(mix(1.0, m, MASK_STRENGTH));
}

float scan_weight(vec2 coord)
{
    float line = coord.y * MAIN_size.y;
    float dist = abs(fract(line) - 0.5);
    float scale = REF_HEIGHT / MAIN_size.y;
    float radius = 0.5 * scale;
    float w = 1.0 - SCAN_STRENGTH * smoothstep(0.0, radius, dist);
    return w;
}

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
    float sw = scan_weight(coord);
    color *= sw;
    vec3 mask = rgb_mask(coord);
    color *= mask;
    color = pow(color, vec3(0.90));
    color *= vignette(MAIN_pos);
    vec3 base = MAIN_tex(MAIN_pos).rgb;
    color = mix(base, color, CRT_STRENGTH);
    return vec4(color, 1.0);
}