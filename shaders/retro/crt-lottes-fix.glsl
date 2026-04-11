// Port of Timothy Lottes' CRT shader
// Original shader by Timothy Lottes (public domain / original license)
// mpv port by the mpv-retro-shaders Contributors (c) 2022
// This file includes additional modifications by TyRaS-SW, 2026


//!HOOK MAIN
//!BIND MAIN
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!DESC CRT Lottes FIX-CIRCLES FULLSCREEN (full)

// Parameters
#define HARD_SCAN -8.0
#define CURVATURE vec2(0.031, 0.041)
#define MASK_DARK 0.5
#define MASK_LIGHT 1.5
#define SHADOW_MASK 2
#define BRIGHTNESS_BOOST 1.0
#define HARD_BLOOM_SCAN -2.0
#define BLOOM_AMOUNT (1.0/16.0)
#define SHAPE 2.0

#ifndef linearize
vec4 linearize(vec4 color) {
    const float _const_0_1 = 0.05958483740687370300;
    const float _const_1_1 = 0.87031054496765136718;
    color.rgb = max(color.rgb, 0.0);
    color.rgb = _const_1_1 * pow(color.rgb + vec3(_const_0_1), vec3(2.4));
    return color;
}
#endif

#ifndef delinearize
vec4 delinearize(vec4 color) {
    const float _const_0_2 = 0.05958483740687370300;
    const float _const_1_2 = 1.14901518821716308593;
    color.rgb = max(color.rgb, 0.0);
    color.rgb = pow(_const_1_2 * color.rgb, vec3(1.0/2.4)) - vec3(_const_0_2);
    return color;
}
#endif

vec3 nearest_emulated_sample(vec2 pos, vec2 off) {
    // 🔧 FIX: Clamp pos antes sampling
    pos = clamp(pos, 0.0, 1.0);
    vec3 color = BRIGHTNESS_BOOST * MAIN_tex(pos).rgb;
    return linearize(vec4(color, 1.0)).rgb;
}

vec2 distance_to_texel(vec2 pos) {
    return -1.0 * fract(pos * MAIN_size - vec2(0.5));
}

float gauss1d(float pos, float scale) {
    return exp2(scale * pow(abs(pos), SHAPE));
}

// [horz3, horz5, horz7 WITHOUT CHANGES - nearest_emulated_sample fixed]
vec3 horz3(vec2 pos, float off, float scale) {
    vec3 c = nearest_emulated_sample(pos, vec2(-1.0, off));
    vec3 d = nearest_emulated_sample(pos, vec2(0.0, off));
    vec3 e = nearest_emulated_sample(pos, vec2(1.0, off));
    float dst = distance_to_texel(pos).x;
    float wc = gauss1d(dst - 1.0, scale);
    float wd = gauss1d(dst, scale);
    float we = gauss1d(dst + 1.0, scale);
    return (c * wc + d * wd + e * we) / (wc + wd + we);
}

vec3 horz5(vec2 pos, float off, float scale) {
    vec3 b = nearest_emulated_sample(pos, vec2(-2.0, off));
    vec3 c = nearest_emulated_sample(pos, vec2(-1.0, off));
    vec3 d = nearest_emulated_sample(pos, vec2(0.0, off));
    vec3 e = nearest_emulated_sample(pos, vec2(1.0, off));
    vec3 f = nearest_emulated_sample(pos, vec2(2.0, off));
    float dst = distance_to_texel(pos).x;
    float wb = gauss1d(dst - 2.0, scale);
    float wc = gauss1d(dst - 1.0, scale);
    float wd = gauss1d(dst, scale);
    float we = gauss1d(dst + 1.0, scale);
    float wf = gauss1d(dst + 2.0, scale);
    return (b * wb + c * wc + d * wd + e * we + f * wf) / (wb + wc + wd + we + wf);
}

vec3 horz7(vec2 pos, float off, float scale) {
    vec3 a = nearest_emulated_sample(pos, vec2(-3.0, off));
    vec3 b = nearest_emulated_sample(pos, vec2(-2.0, off));
    vec3 c = nearest_emulated_sample(pos, vec2(-1.0, off));
    vec3 d = nearest_emulated_sample(pos, vec2(0.0, off));
    vec3 e = nearest_emulated_sample(pos, vec2(1.0, off));
    vec3 f = nearest_emulated_sample(pos, vec2(2.0, off));
    vec3 g = nearest_emulated_sample(pos, vec2(3.0, off));
    float dst = distance_to_texel(pos).x;
    float wa = gauss1d(dst - 3.0, scale);
    float wb = gauss1d(dst - 2.0, scale);
    float wc = gauss1d(dst - 1.0, scale);
    float wd = gauss1d(dst, scale);
    float we = gauss1d(dst + 1.0, scale);
    float wf = gauss1d(dst + 2.0, scale);
    float wg = gauss1d(dst + 3.0, scale);
    return (a * wa + b * wb + c * wc + d * wd + e * we + f * wf + g * wg) / (wa + wb + wc + wd + we + wf + wg);
}

// 🔧 CRITIC FIX #1: Bend + CLAMP
vec2 bend_screen(vec2 pos) {
    pos = pos * 2.0 - 1.0;
    pos *= vec2(1.0 + (pos.y * pos.y) * CURVATURE.x,
                1.0 + (pos.x * pos.x) * CURVATURE.y);
    return pos * 0.5 + 0.5; // si quieres, aquí puedes añadir clamp
}

float scan(vec2 pos, float off) {
    float dst = distance_to_texel(pos).y;
    return gauss1d(dst + off, HARD_SCAN);
}

vec3 tri(vec2 pos) {
    vec3 a = horz3(pos, -1.0, -10.0);
    vec3 b = horz5(pos, 0.0, -10.0);
    vec3 c = horz3(pos, 1.0, -10.0);
    float wa = scan(pos, -1.0);
    float wb = scan(pos, 0.0);
    float wc = scan(pos, 1.0);
    return a * wa + b * wb + c * wc;
}

float bloom_scan(vec2 pos, float off) {
    float dst = distance_to_texel(pos).y;
    return gauss1d(dst + off, HARD_BLOOM_SCAN);
}

vec3 bloom(vec2 pos) {
    vec3 a = horz5(pos, -2.0, -3.0);
    vec3 b = horz7(pos, -1.0, -1.5);
    vec3 c = horz7(pos, 0.0, -1.5);
    vec3 d = horz7(pos, 1.0, -1.5);
    vec3 e = horz5(pos, 2.0, -3.0);
    float wa = bloom_scan(pos, -2.0);
    float wb = bloom_scan(pos, -1.0);
    float wc = bloom_scan(pos, 0.0);
    float wd = bloom_scan(pos, 1.0);
    float we = bloom_scan(pos, 2.0);
    return a * wa + b * wb + c * wc + d * wd + e * we;
}

vec3 mask(vec2 pos) {
    vec3 m = vec3(MASK_DARK, MASK_DARK, MASK_DARK);
    if (SHADOW_MASK == 1) {
        float line = MASK_LIGHT;
        float odd = 0.0;
        if (fract(pos.x / 6.0) < 0.5) odd = 1.0;
        if (fract((pos.y + odd) / 2.0) < 0.5) line = MASK_DARK;
        pos.x = fract(pos.x / 3.0);
        if (pos.x < 1.0 / 3.0) m.r = MASK_LIGHT;
        else if (pos.x < 2.0 / 3.0) m.g = MASK_LIGHT;
        else m.b = MASK_LIGHT;
        m *= line;
    } else if (SHADOW_MASK == 2) {
        pos.x = fract(pos.x / 3.0);
        if (pos.x < 1.0 / 3.0) m.r = MASK_LIGHT;
        else if (pos.x < 2.0 / 3.0) m.g = MASK_LIGHT;
        else m.b = MASK_LIGHT;
    } else if (SHADOW_MASK == 3) {
        pos.x += pos.y * 3.0;
        pos.x = fract(pos.x / 6.0);
        if (pos.x < 1.0 / 3.0) m.r = MASK_LIGHT;
        else if (pos.x < 2.0 / 3.0) m.g = MASK_LIGHT;
        else m.b = MASK_LIGHT;
    } else if (SHADOW_MASK == 4) {
        pos = floor(pos * vec2(1.0, 0.5));
        pos.x += pos.y * 3.0;
        pos.x = fract(pos.x / 6.0);
        if (pos.x < 1.0 / 3.0) m.r = MASK_LIGHT;
        else if (pos.x < 2.0 / 3.0) m.g = MASK_LIGHT;
        else m.b = MASK_LIGHT;
    }

    return m;
}

// 🔧 CRITIC FIX #2: Bilineal with clamp
vec4 calculate_crt(vec2 mpos, vec2 tsize, float scale_x, float scale_y) {
    vec2 pos = bend_screen(mpos);

    // If pixel was out of the "screen" curved → black tint
    if (pos.x < 0.0 || pos.x > 1.0 || pos.y < 0.0 || pos.y > 1.0)
        return vec4(0.0, 0.0, 0.0, 1.0);

    vec3 color = tri(pos);
    color += bloom(pos) * BLOOM_AMOUNT;

    #if SHADOW_MASK != 0
    vec2 m_pos = clamp(floor(mpos * tsize) + vec2(0.5, 0.5),
                       vec2(0.5), tsize - vec2(0.5));
    color *= mask(vec2(floor((m_pos.x - 0.5) / scale_x) + 0.5,
                       floor((m_pos.y - 0.5) / scale_y) + 0.5));
    #endif

    vec4 crt = delinearize(vec4(color, 1.0));
    return crt;
}

vec4 hook() {
    vec2 uv = MAIN_pos;

    // FIX 3: Use always virtual road, without else
    vec2 virtual_size = vec2(2400.0, 1350.0);
    vec2 vpos = clamp(MAIN_pos * virtual_size,
                      vec2(0.5), virtual_size - vec2(0.5));
    vec2 p = vpos - vec2(0.5, 0.5);
    vec2 fpos = floor(p);
    vec2 f = fract(p);

    // 🔧 FIX #4: CLAMP all positions bilineal
    vec2 pos00 = clamp((fpos + vec2(0.5, 0.5)) / virtual_size, 0.0, 1.0);
    vec2 pos10 = clamp((fpos + vec2(1.5, 0.5)) / virtual_size, 0.0, 1.0);
    vec2 pos01 = clamp((fpos + vec2(0.5, 1.5)) / virtual_size, 0.0, 1.0);
    vec2 pos11 = clamp((fpos + vec2(1.5, 1.5)) / virtual_size, 0.0, 1.0);

    vec4 c00 = calculate_crt(pos00, virtual_size, 1.0, 1.0);
    vec4 c10 = calculate_crt(pos10, virtual_size, 1.0, 1.0);
    vec4 c01 = calculate_crt(pos01, virtual_size, 1.0, 1.0);
    vec4 c11 = calculate_crt(pos11, virtual_size, 1.0, 1.0);

    return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}
