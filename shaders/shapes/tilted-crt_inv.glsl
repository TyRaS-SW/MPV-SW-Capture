// Tilted CRT (keystone inverted, pivot) Shape. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//!HOOK MAIN
//!BIND MAIN
//!DESC Form - Tilted CRT (keystone inverted, pivot)

// Amount of vertical keystone (0.0 = none, 0.15 = visible)
#define KEYSTONE 0.1

// Vertical pivot of the tilt in -1..1
//  0.0 = center (original behavior)
//  negative = push the tilt downward
//  positive = push the tilt upward
#define Y_PIVOT 1.0

vec2 apply_keystone(vec2 uv)
{
    // Map to -1..1
    vec2 p = uv * 2.0 - 1.0;

    // Shift Y so the tilt pivot is moved
    float y_rel = p.y - Y_PIVOT;

    // Inverted: bottom narrower, top wider, relative to the pivot
    float k = 1.0 - KEYSTONE * y_rel;
    p.x *= k;

    // Back to original Y position
    // (no need to change p.y because we only tilt in X)
    // Back to 0..1
    return p * 0.5 + 0.5;
}

vec4 hook()
{
    vec2 uv = apply_keystone(MAIN_pos);

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0);

    return MAIN_tex(uv);
}