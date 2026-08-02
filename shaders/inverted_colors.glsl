// Inverted Colors. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)

//!HOOK MAIN
//!BIND HOOKED
//!DESC Inverted Colors

vec4 hook() {
    // Inverted Colors
    vec3 color = HOOKED_tex(HOOKED_pos).rgb;
    return vec4(1.0 - color, 1.0);
}