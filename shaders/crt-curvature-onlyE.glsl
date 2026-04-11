// This file is inspired in CRT Lottes curvature. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//!HOOK MAIN
//!BIND MAIN
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!DESC CRT Curvature + Vignette

#define CURVATURE vec2(0.031, 0.041)

#define VIGNETTE_STRENGTH 2.0

vec2 bend_screen(vec2 pos) {
    pos = pos * 2.0 - 1.0;
    pos *= vec2(1.0 + (pos.y * pos.y) * CURVATURE.x,
                1.0 + (pos.x * pos.x) * CURVATURE.y);
    return pos * 0.5 + 0.5;
}

float fragment_vign(vec2 vpos) {
    vpos = vpos * (1.0 - vpos);
    float vig = max(vpos.x * vpos.y * 45.0, 0.0);
    float base = min(pow(vig, 0.15), 1.0);   // 0..1
    return mix(1.0, base, clamp(VIGNETTE_STRENGTH, 0.0, 2.0));
}

vec4 hook() {
    vec2 pos = bend_screen(MAIN_pos);

    // Black borders
    if (pos.x < 0.0 || pos.x > 1.0 || pos.y < 0.0 || pos.y > 1.0)
        return vec4(0.0, 0.0, 0.0, 1.0);

    vec4 color = MAIN_tex(pos);

    float v = fragment_vign(MAIN_pos);
    color.rgb *= v;

    return color;
}
