// LCD Dust - Pure Dust Effect
// Only dust, nothing else. No curvature, no bloom, no gamma, no vignette.
// Uses screen coordinates so the dust pattern is fixed on the display.
// By TyRaS-SW, 2026

//!HOOK MAIN
//!BIND MAIN
//!DESC LCD Dirty TV (Pure Dust)

// Parameters
#define DUST_STRENGTH  0.65   // Dust intensity (0.1-0.6) - INCREASED
#define MIX_FACTOR     0.85   // How much dust to mix with original (0.0-1.0) - INCREASED

// --- Helper: pseudo-random function ---
float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// 2D value noise
float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fixed dust effect using screen coordinates (target_size)
float dust_effect(vec2 coord)
{
    vec2 screen_pos = coord * target_size;
    float grain_scale = 2.0;
    vec2 scaled_pos = screen_pos / grain_scale;
    float n = noise(scaled_pos);
    float dust = 1.0 - DUST_STRENGTH * (n - 0.5) * 2.0;
    dust = clamp(dust, 0.3, 1.2);  // Lowered clamp minimum for more dust
    return dust;
}

vec4 hook()
{
    vec3 color = MAIN_tex(MAIN_pos).rgb;
    float dust = dust_effect(MAIN_pos);
    vec3 dusty_color = color * dust;
    vec3 final_color = mix(color, dusty_color, MIX_FACTOR);
    return vec4(final_color, 1.0);
}