// This file is inspired in a CRT Barrel Distortion form. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//!HOOK MAIN
//!BIND MAIN
//!DESC CRT Wide Barrel transparent

#define warpX 0.0
#define warpY 0.05
#define vignette 0.0

// Width of the anti-aliased edge in UV space (~1 pixel)
#define EDGE_AA 0.001

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

    if (warp_pos.x < -EDGE_AA || warp_pos.x > 1.0 + EDGE_AA ||
        warp_pos.y < -EDGE_AA || warp_pos.y > 1.0 + EDGE_AA)
        return vec4(0.0, 0.0, 0.0, 1.0);

    vec2 clamped = clamp(warp_pos, 0.0, 1.0);
    vec4 color = MAIN_tex(clamped);
    color.rgb *= fragment_vign(clamped);

    float mask_x = smoothstep(0.0, EDGE_AA, warp_pos.x) *
                   smoothstep(1.0, 1.0 - EDGE_AA, warp_pos.x);
    float mask_y = smoothstep(0.0, EDGE_AA, warp_pos.y) *
                   smoothstep(1.0, 1.0 - EDGE_AA, warp_pos.y);
    float mask = mask_x * mask_y;

    return vec4(color.rgb * mask, 1.0);
}
