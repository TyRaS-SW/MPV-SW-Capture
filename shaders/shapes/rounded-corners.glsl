// Round Corners Shape. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//!HOOK MAIN
//!BIND MAIN
//!DESC Form - Rounded Corners (Balanced)

// Corner radius size (0.0–0.5)
#define CORNER_RADIUS 0.15

// Edge thickness for antialiasing
#define EDGE_SOFTNESS 0.0035

float roundedRect(vec2 p, vec2 b, float r)
{
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, 0.0)) - r + min(max(q.x, q.y), 0.0);
}

vec4 hook()
{
    // Centered coordinates -1..1
    vec2 p = MAIN_pos * 2.0 - 1.0;

    // Inner rectangle:
    //  - Small inset on X → thin but visible left/right border
    //  - Small inset on Y → thin top/bottom border
    vec2 halfSize = vec2(1.0 - 0.0015, 1.0 - 0.0015);

    float d = roundedRect(p, halfSize, CORNER_RADIUS);

    // Alpha mask
    float alpha = 1.0 - smoothstep(0.0, EDGE_SOFTNESS, d);

    vec3 color = MAIN_tex(MAIN_pos).rgb;
    color *= alpha;

    return vec4(color, 1.0);
}