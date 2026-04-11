// This file is inspired in CRT Lottes curvature. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//!HOOK MAIN
//!BIND MAIN
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!DESC CRT Curvature

#define CURVATURE vec2(0.031, 0.041)

// Similar curvature as CRT Lottes FIX
vec2 bend_screen(vec2 pos) {
    pos = pos * 2.0 - 1.0;
    pos *= vec2(1.0 + (pos.y * pos.y) * CURVATURE.x,
                1.0 + (pos.x * pos.x) * CURVATURE.y);
    return pos * 0.5 + 0.5;
}

vec4 hook() {
    // Normalized screen coordinates
    vec2 pos = bend_screen(MAIN_pos);

    // Same "off-screen" criteria as we use in the full Lottes:
    // everything that falls outside [0,1] after the curvature → solid black.
    if (pos.x < 0.0 || pos.x > 1.0 || pos.y < 0.0 || pos.y > 1.0)
        return vec4(0.0, 0.0, 0.0, 1.0);

    // Within the curved area, sample normal
    return MAIN_tex(pos);
}
