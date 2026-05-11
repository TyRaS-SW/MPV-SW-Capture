// Tilted CRT (Inward Keystone, Less Bottom Zoom) Shape. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//!HOOK MAIN
//!BIND MAIN
//!DESC Form - Tilted CRT (Inward Keystone, Less Bottom Zoom)

// Base keystone amount (0.0 = none, 0.2 = strong-ish)
#define KEYSTONE 0.10

// How much to compress the bottom (0.0 = none, 0.3 = noticeable)
#define BOTTOM_RELAX 0.0

vec2 apply_keystone(vec2 uv)
{
    // --- 1) Pre‑deform Y para ver "más" parte de abajo ---

    // uv.y: 0 = bottom, 1 = top
    float y = uv.y;

    // Curva que comprime un poco la zona inferior:
    //   - cerca de 0 (bottom) la pendiente baja → "menos zoom"
    //   - cerca de 1 (top) casi no cambia
    float t = pow(y, 1.0 + BOTTOM_RELAX);  // y^(1+relax)
    float y_relaxed = mix(y, t, BOTTOM_RELAX);

    vec2 uv_relaxed = vec2(uv.x, y_relaxed);

    // --- 2) Keystone "inward" como el tuyo, usando uv_relaxed ---

    // Map 0..1 → -1..1
    vec2 p = uv_relaxed * 2.0 - 1.0;

    // Normalized height 0..1 (0 = bottom, 1 = top)
    float h = (p.y + 1.0) * 0.9;

    // Stronger effect near the top
    float curve = h * h * h;

    // Inverted keystone: bottom narrower, top wider
    float k = 1.0 - KEYSTONE * curve;
    p.x *= k;

    // Back to 0..1
    return p * 0.5 + 0.5;
}

vec4 hook()
{
    vec2 uv = apply_keystone(MAIN_pos);

    // Outside area → black (only if KEYSTONE/BOTTOM_RELAX are too high)
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0);

    return MAIN_tex(uv);
}