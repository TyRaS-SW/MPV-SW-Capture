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

    // Outside area → black (only if KEYSTONE is too strong)
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0);

    return MAIN_tex(uv);
}