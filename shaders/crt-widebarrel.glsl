// This file is inspired in a CRT Barrel Distortion form. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//!HOOK MAIN
//!BIND MAIN
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!DESC CRT Wide Barrel transparent

#define warpX 0.0
#define warpY 0.05
#define vignette 0.0

vec2 fragment_Warp(vec2 pos) {
    pos = pos * 2.0 - 1.0;
    pos *= vec2(1.0 + (pos.y * pos.y) * warpX, 1.0 + (pos.x * pos.x) * warpY);
    return pos * 0.5 + 0.5;
}

float fragment_vign(vec2 vpos) {
    if (vignette == 0.0) return 1.0;
    vpos = vpos * (1.0 - vpos); 
    float vig = max(vpos.x * vpos.y * 45.0, 0.0);
    return min(pow(vig, 0.15), 1.0);
}

vec4 hook() {
    vec2 warp_pos = fragment_Warp(MAIN_pos);

    vec4 color = MAIN_tex(warp_pos);
    color.rgb *= fragment_vign(warp_pos);

    float in_bounds = step(0.0, warp_pos.x) * step(warp_pos.x, 1.0) * 
                      step(0.0, warp_pos.y) * step(warp_pos.y, 1.0);

    // BLACK FILL only transparencies (ORIGINAL shape)
    vec4 final_color = in_bounds * color;
    return mix(vec4(0.0, 0.0, 0.0, 1.0), final_color, in_bounds);
}