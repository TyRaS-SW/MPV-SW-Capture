// Tilted CRT (keystone, pivot) Shape. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//!HOOK MAIN
//!BIND MAIN
//!DESC Shape - Tilted CRT (keystone, pivot)

// Amount of vertical keystone (0.0 = none, 0.15 = visible)
#define KEYSTONE 0.1

// Vertical pivot of the tilt in -1..1
//  0.0 = center (original behavior)
//  negative = push the tilt downward
//  positive = push the tilt upward
#define Y_PIVOT -1.0

// Width of the anti-aliased edge in UV space (~1 pixel)
#define EDGE_AA 0.001

vec2 apply_keystone(vec2 uv)
{
    // Map to -1..1
    vec2 p = uv * 2.0 - 1.0;

    // Shift Y so the tilt pivot is moved
    float y_rel = p.y - Y_PIVOT;

    // Normal keystone: top narrower, bottom wider (relative to pivot)
    float k = 1.0 + KEYSTONE * y_rel;
    p.x *= k;

    // Back to 0..1
    return p * 0.5 + 0.5;
}

vec4 hook()
{
    vec2 uv = apply_keystone(MAIN_pos);

    if (uv.x < -EDGE_AA || uv.x > 1.0 + EDGE_AA ||
        uv.y < -EDGE_AA || uv.y > 1.0 + EDGE_AA)
        return vec4(0.0, 0.0, 0.0, 1.0);

    vec2 clamped = clamp(uv, 0.0, 1.0);
    vec4 color = MAIN_tex(clamped);

    float mask_x = smoothstep(0.0, EDGE_AA, uv.x) *
                   smoothstep(1.0, 1.0 - EDGE_AA, uv.x);
    float mask_y = smoothstep(0.0, EDGE_AA, uv.y) *
                   smoothstep(1.0, 1.0 - EDGE_AA, uv.y);
    float mask = mask_x * mask_y;

    return vec4(color.rgb * mask, 1.0);
}
