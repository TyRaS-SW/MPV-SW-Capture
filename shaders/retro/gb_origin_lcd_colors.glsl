// Derived from crt-guest-sm.glsl
// Modified by TyRaS-SW, 2026
// This experimental port produced a useful greenish-screen effect and became the basis
// for gb_origin_lcd_colors.
//
// FIX: Auto-scale scanline and mask parameters based on input height to keep
// the same visual effect at any resolution (reference: 1080p).

//!PARAM WP
//!DESC Color Temperature %
//!TYPE CONSTANT float
//!MINIMUM -100
//!MAXIMUM 100
0

//!PARAM beam_max
//!DESC Scanline bright
//!TYPE CONSTANT float
//!MINIMUM 0.5
//!MAXIMUM 2
1.1

//!PARAM beam_min
//!DESC Scanline dark
//!TYPE CONSTANT float
//!MINIMUM 0.5
//!MAXIMUM 2
1.4

//!PARAM brightboost1
//!DESC Bright boost dark colors
//!TYPE CONSTANT float
//!MINIMUM 0.5
//!MAXIMUM 3
1.5

//!PARAM brightboost2
//!DESC Bright boost bright colors
//!TYPE CONSTANT float
//!MINIMUM 0.5
//!MAXIMUM 2
1.1

//!PARAM gamma_out
//!DESC Gamma Out
//!TYPE CONSTANT float
//!MINIMUM 1
//!MAXIMUM 3
2.4

//!PARAM h_sharp
//!DESC Horizontal sharpness
//!TYPE CONSTANT float
//!MINIMUM 1
//!MAXIMUM 5
2

//!PARAM mask
//!DESC CRT Mask (3&4 are 4k masks)
//!TYPE CONSTANT float
//!MINIMUM 0
//!MAXIMUM 4
0

//!PARAM maskbright
//!DESC CRT Mask Strength Bright Pixels
//!TYPE CONSTANT float
//!MINIMUM -0.5
//!MAXIMUM 1
0.2

//!PARAM maskdark
//!DESC CRT Mask Strength Dark Pixels
//!TYPE CONSTANT float
//!MINIMUM 0
//!MAXIMUM 1.5
1

//!PARAM maskmode
//!DESC CRT Mask Mode: Classic, Fine, Coarse
//!TYPE CONSTANT float
//!MINIMUM 0
//!MAXIMUM 2
0

//!PARAM masksize
//!DESC CRT Mask Size
//!TYPE CONSTANT float
//!MINIMUM 1
//!MAXIMUM 2
1

//!PARAM mask_ref_x
//!DESC Virtual Mask Ref Width
//!TYPE CONSTANT float
//!MINIMUM 320
//!MAXIMUM 7680
3840

//!PARAM mask_ref_y
//!DESC Virtual Mask Ref Height
//!TYPE CONSTANT float
//!MINIMUM 240
//!MAXIMUM 4320
2160

//!PARAM s_beam
//!DESC Overgrown Bright Beam
//!TYPE CONSTANT float
//!MINIMUM 0
//!MAXIMUM 1
0.75

//!PARAM saturation1
//!DESC Scanline Saturation
//!TYPE CONSTANT float
//!MINIMUM 0
//!MAXIMUM 6
2.75

//!PARAM scanline1
//!DESC Scanline Shape Center
//!TYPE CONSTANT float
//!MINIMUM 2
//!MAXIMUM 14
8

//!PARAM scanline2
//!DESC Scanline Shape Edges
//!TYPE CONSTANT float
//!MINIMUM 4
//!MAXIMUM 16
8

//!PARAM smart
//!DESC Smart Y Integer Scaling
//!TYPE CONSTANT float
//!MINIMUM 0
//!MAXIMUM 1
0

//!PARAM stype
//!DESC Scanline Type
//!TYPE CONSTANT float
//!MINIMUM 0
//!MAXIMUM 2
0

//!PARAM wp_saturation
//!DESC Saturation Adjustment
//!TYPE CONSTANT float
//!MINIMUM 0
//!MAXIMUM 2
1

//!HOOK MAIN
//!COMPONENTS 4
//!DESC sRGB to linear RGB
//!SAVE MAIN_RGB
//!BIND HOOKED

vec4 hook() {
	return HOOKED_tex(HOOKED_pos);
}

//!HOOK MAIN
//!COMPONENTS 2
//!DESC store viewport size
//!SAVE VIEWPORT
//!WIDTH OUTPUT.width
//!HEIGHT OUTPUT.height

vec4 hook() {
	return vec4(target_size, 0.0, 0.0);
}

//!HOOK MAIN
//!COMPONENTS 4
//!DESC d65-d50.slang
//!SAVE _PASS_0
//!BIND MAIN_RGB
//!BIND HOOKED

vec4 vertex_gl_Position;
struct _params_ {
    vec4 SourceSize;
    vec4 OriginalSize;
    vec4 OutputSize;
    uint FrameCount;
    float WP;
    float wp_saturation;
} params = _params_(vec4(MAIN_RGB_size, MAIN_RGB_pt), vec4(MAIN_RGB_size, MAIN_RGB_pt), vec4(target_size, 1. / target_size.x, 1. / target_size.y), uint(frame), float(WP), float(wp_saturation));
struct _global_ {
    mat4 MVP;
} global = _global_(mat4(1.));
vec4 Position = vec4(HOOKED_pos, 0., 1.);
vec2 TexCoord = HOOKED_pos;
vec2 vTexCoord;
void vertex_main() {
    vertex_gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
}

vec4 FragColor;
#define Source MAIN_RGB_raw
const mat3 fragment_D65_to_XYZ = mat3(0.430619, 0.2220379, 0.0201853, 0.3415419, 0.7066384, 0.1295504, 0.1783091, 0.0713236, 0.9390944);
const mat3 fragment_XYZ_to_D65 = mat3(3.0628972, -0.969266, 0.0678775, -1.393179, 1.8760108, -0.2288548, -0.4757517, 0.041556, 1.069349);
const mat3 fragment_D50_to_XYZ = mat3(0.4552773, 0.2323025, 0.0145457, 0.36755, 0.7077956, 0.1049154, 0.1413926, 0.0599019, 0.7057489);
const mat3 fragment_XYZ_to_D50 = mat3(2.9603944, -0.9787684, 0.0844874, -1.4678519, 1.9161415, -0.2545973, -0.4685105, 0.033454, 1.4216174);
void fragment_main() {
    vec3 color = texture(Source, vTexCoord.xy).rgb;
    color = normalize(pow(color + 0.0001, vec3(params.wp_saturation))) * length(color);
    float p = 2.4;
    color = pow(color, vec3(p));
    vec3 warmer = fragment_D50_to_XYZ * color;
    warmer = fragment_XYZ_to_D65 * warmer;
    vec3 cooler = fragment_D65_to_XYZ * color;
    cooler = fragment_XYZ_to_D50 * cooler;
    float m = abs(params.WP) / 100.;
    vec3 comp = params.WP < 0. ? cooler : warmer;
    color = mix(color, comp, m);
    color = pow(color, vec3(1. / p));
    FragColor = vec4(color, 1.);
}

vec4 hook() {
    vertex_main();
    fragment_main();
    return FragColor;
}


//!HOOK MAIN
//!COMPONENTS 4
//!DESC crt-guest-sm.slang (auto-scaled)
//!WIDTH _PASS_0.width 1 *
//!HEIGHT _PASS_0.height 1 *
//!BIND MAIN_RGB
//!BIND HOOKED
//!BIND _PASS_0

vec4 vertex_gl_Position;
struct _params_ {
    vec4 SourceSize;
    vec4 OriginalSize;
    vec4 OutputSize;
    uint FrameCount;
    float smart, brightboost1, brightboost2, stype, scanline1, scanline2;
    float beam_min, beam_max, s_beam, saturation1, h_sharp;
    float mask, maskmode, maskdark, maskbright, masksize, gamma_out;
    float mask_ref_x, mask_ref_y;
} params = _params_(
    vec4(_PASS_0_size, _PASS_0_pt),
    vec4(MAIN_RGB_size, MAIN_RGB_pt),
    vec4(target_size, 1. / target_size.x, 1. / target_size.y),
    uint(frame),
    float(smart), float(brightboost1), float(brightboost2), float(stype),
    float(scanline1), float(scanline2), float(beam_min), float(beam_max),
    float(s_beam), float(saturation1), float(h_sharp), float(mask),
    float(maskmode), float(maskdark), float(maskbright), float(masksize),
    float(gamma_out), float(mask_ref_x), float(mask_ref_y)
);
struct _global_ {
    mat4 MVP;
} global = _global_(mat4(1.));
vec4 Position = vec4(HOOKED_pos, 0., 1.);
vec2 TexCoord = HOOKED_pos;
vec2 vTexCoord;
void vertex_main() {
    vertex_gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
}

vec4 FragColor;
#define Source _PASS_0_raw
float fragment_st(float x) {
    return exp2(-10. * x * x);
}

float fragment_st1(float x, float scan) {
    return exp2(-scan * x * x);
}

float fragment_sw1(float x, vec3 color, float scan) {
    float mx = max(max(color.r, color.g), color.b);
    float ex = mix((2.75 - 1.75 * params.stype) * params.beam_min, params.beam_max, mx);
    ex = mix(params.beam_max, ex, pow(x, mx + 0.25)) * x;
    return exp2(-scan * ex * ex);
}

float fragment_sw2(float x, vec3 color) {
    float mx = max(max(color.r, color.g), color.b);
    float ex = mix(2. * params.beam_min, params.beam_max, mx);
    float m = 0.5 * ex;
    x = x * ex;
    float xx = x * x;
    xx = mix(xx, x * xx, m);
    return exp2(-10. * xx);
}

float fragment_Overscan(float pos, float dy) {
    pos = pos * 2. - 1.;
    pos *= dy;
    return pos * 0.5 + 0.5;
}

void fragment_main() {
    // --- AUTO-SCALE PARAMETERS BASED ON INPUT HEIGHT (REF: 1080) ---
    const float refHeight = 1080.0;
    float scaleY = params.SourceSize.y / refHeight;

    float scanline1_scaled = params.scanline1 * scaleY;
    float scanline2_scaled = params.scanline2 * scaleY;
    float beam_min_scaled   = params.beam_min * scaleY;
    float beam_max_scaled   = params.beam_max * scaleY;
    float s_beam_scaled     = params.s_beam;  // This is a ratio, not a length
    float masksize_scaled   = params.masksize; // This is a multiplier, not a length
    // The mask reference dimensions are also scaled to keep the pattern density constant.
    float mask_ref_x_scaled = params.mask_ref_x * scaleY;
    float mask_ref_y_scaled = params.mask_ref_y * scaleY;

    vec2 tex = clamp(vTexCoord.xy, vec2(0.0), vec2(1.0));
    if (params.smart == 1.) {
        float factor = params.OutputSize.y / params.SourceSize.y;
        float intfactor = round(factor);
        float diff = factor / intfactor;
        tex.y = fragment_Overscan(tex.y * (params.SourceSize.y / params.SourceSize.y), diff) * (params.SourceSize.y / params.SourceSize.y);
    }
    vec2 OGL2Pos = tex * params.SourceSize.xy - vec2(0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;
    vec3 ul = texture(Source, pC4).xyz;
    ul *= ul;
    vec3 ur = texture(Source, pC4 + vec2(params.SourceSize.z, 0.)).xyz;
    ur *= ur;
    vec3 dl = texture(Source, pC4 + vec2(0., params.SourceSize.w)).xyz;
    dl *= dl;
    vec3 dr = texture(Source, pC4 + params.SourceSize.zw).xyz;
    dr *= dr;
    float lx = fp.x;
    lx = pow(lx, params.h_sharp);
    float rx = 1. - fp.x;
    rx = pow(rx, params.h_sharp);
    float w = 1. / (lx + rx);
    float f1 = fp.y;
    float f2 = 1. - fp.y;
    float f3 = fract(tex.y * params.SourceSize.y);
    f3 = abs(f3 - 0.5);
    vec3 color;
    float t1 = fragment_st(f1);
    float t2 = fragment_st(f2);
    float wt = 1. / (t1 + t2);
    vec3 cl = (ul * t1 + dl * t2) * wt;
    vec3 cr = (ur * t1 + dr * t2) * wt;
    vec3 ref_ul = mix(cl, ul, s_beam_scaled);
    vec3 ref_ur = mix(cr, ur, s_beam_scaled);
    vec3 ref_dl = mix(cl, dl, s_beam_scaled);
    vec3 ref_dr = mix(cr, dr, s_beam_scaled);
    float scan1 = mix(scanline1_scaled, scanline2_scaled, f1);
    float scan2 = mix(scanline1_scaled, scanline2_scaled, f2);
    float scan0 = mix(scanline1_scaled, scanline2_scaled, f3);
    f3 = fragment_st1(f3, scan0);
    f3 = f3 * f3 * (3. - 2. * f3);
    float w1, w2, w3, w4 = 0.;
    if (params.stype < 2.) {
        // Use scaled beam values in sw1
        float beam_min_sw = beam_min_scaled;
        float beam_max_sw = beam_max_scaled;
        // Re-define sw1 logic inline with scaled beams
        {
            float mx = max(max(ref_ul.r, ref_ul.g), ref_ul.b);
            float ex = mix((2.75 - 1.75 * params.stype) * beam_min_sw, beam_max_sw, mx);
            ex = mix(beam_max_sw, ex, pow(f1, mx + 0.25)) * f1;
            w1 = exp2(-scan1 * ex * ex);
        }
        {
            float mx = max(max(ref_dl.r, ref_dl.g), ref_dl.b);
            float ex = mix((2.75 - 1.75 * params.stype) * beam_min_sw, beam_max_sw, mx);
            ex = mix(beam_max_sw, ex, pow(f2, mx + 0.25)) * f2;
            w2 = exp2(-scan2 * ex * ex);
        }
        {
            float mx = max(max(ref_ur.r, ref_ur.g), ref_ur.b);
            float ex = mix((2.75 - 1.75 * params.stype) * beam_min_sw, beam_max_sw, mx);
            ex = mix(beam_max_sw, ex, pow(f1, mx + 0.25)) * f1;
            w3 = exp2(-scan1 * ex * ex);
        }
        {
            float mx = max(max(ref_dr.r, ref_dr.g), ref_dr.b);
            float ex = mix((2.75 - 1.75 * params.stype) * beam_min_sw, beam_max_sw, mx);
            ex = mix(beam_max_sw, ex, pow(f2, mx + 0.25)) * f2;
            w4 = exp2(-scan2 * ex * ex);
        }
    } else {
        // Use scaled beam values in sw2
        float beam_min_sw = beam_min_scaled;
        float beam_max_sw = beam_max_scaled;
        {
            float mx = max(max(ref_ul.r, ref_ul.g), ref_ul.b);
            float ex = mix(2. * beam_min_sw, beam_max_sw, mx);
            float m = 0.5 * ex;
            float x = f1 * ex;
            float xx = x * x;
            xx = mix(xx, x * xx, m);
            w1 = exp2(-10. * xx);
        }
        {
            float mx = max(max(ref_dl.r, ref_dl.g), ref_dl.b);
            float ex = mix(2. * beam_min_sw, beam_max_sw, mx);
            float m = 0.5 * ex;
            float x = f2 * ex;
            float xx = x * x;
            xx = mix(xx, x * xx, m);
            w2 = exp2(-10. * xx);
        }
        {
            float mx = max(max(ref_ur.r, ref_ur.g), ref_ur.b);
            float ex = mix(2. * beam_min_sw, beam_max_sw, mx);
            float m = 0.5 * ex;
            float x = f1 * ex;
            float xx = x * x;
            xx = mix(xx, x * xx, m);
            w3 = exp2(-10. * xx);
        }
        {
            float mx = max(max(ref_dr.r, ref_dr.g), ref_dr.b);
            float ex = mix(2. * beam_min_sw, beam_max_sw, mx);
            float m = 0.5 * ex;
            float x = f2 * ex;
            float xx = x * x;
            xx = mix(xx, x * xx, m);
            w4 = exp2(-10. * xx);
        }
    }
    vec3 colorl = w1 * ul + w2 * dl;
    vec3 colorr = w3 * ur + w4 * dr;
    color = w * (colorr * lx + colorl * rx);
    color = min(color, 1.);
    vec3 ctemp = w * (cr * lx + cl * rx);
    cl *= cl * cl;
    cl *= cl;
    cr *= cr * cr;
    cr *= cr;
    vec3 sctemp = w * (cr * lx + cl * rx);
    sctemp = pow(sctemp, vec3(1. / 6.));
    float mx1 = max(max(color.r, color.g), color.b);
    float sp = params.stype == 1. ? 0.5 * params.saturation1 : params.saturation1;
    vec3 saturated_color = max((1. + sp) * color - 0.5 * sp * (color + mx1), 0.);
    color = mix(saturated_color, color, f3);
    vec3 scan3 = vec3(0.);
    // Use scaled mask reference resolution
    vec2 ref_res = vec2(mask_ref_x_scaled, mask_ref_y_scaled);
    vec2 ref_px  = floor(tex * ref_res + vec2(0.5));
    float spos   = floor(ref_px.x / masksize_scaled);
    float spos1  = 0.;
    vec3 tmp1 = 0.5 * (sqrt(ctemp) + sctemp);
    color *= mix(params.brightboost1, params.brightboost2, max(max(ctemp.r, ctemp.g), ctemp.b));
    color = min(color, 1.);
    float mboost = 1.25;
    if (params.mask == 0.) {
        spos1 = fract(spos * 0.5);
        if (spos1 < 0.5) scan3.rb = color.rb; else scan3.g = color.g;
    } else if (params.mask == 1.) {
        spos1 = fract(spos * 0.5);
        if (spos1 < 0.5) scan3.rg = color.rg; else scan3.b = color.b;
    } else if (params.mask == 2.) {
        mboost = 1.;
        spos1 = fract(spos / 3.);
        if (spos1 < 0.333) scan3.r = color.r; else if (spos1 < 0.666) scan3.g = color.g; else scan3.b = color.b;
    } else if (params.mask == 3.) {
        spos1 = fract(spos * 0.25);
        if (spos1 < 0.25) scan3.r = color.r; else if (spos1 < 0.5) scan3.rg = color.rg; else if (spos1 < 0.75) scan3.gb = color.gb; else scan3.b = color.b;
    } else {
        spos1 = fract(spos * 0.25);
        if (spos1 < 0.25) scan3.r = color.r; else if (spos1 < 0.5) scan3.rb = color.rb; else if (spos1 < 0.75) scan3.gb = color.gb; else scan3.g = color.g;
    }
    vec3 lerpmask = tmp1;
    if (params.maskmode == 1.) lerpmask = vec3(max(max(tmp1.r, tmp1.g), tmp1.b)); else if (params.maskmode == 2.) lerpmask = color;
    color = max(mix(mix(color, mboost * scan3, params.maskdark), mix(color, scan3, params.maskbright), lerpmask), 0.);
    float y = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(y), 0.70);
    vec3 color1 = pow(color, vec3(1. / 2.1));
    if (params.stype != 1.) {
        vec3 color2 = pow(color, vec3(1. / params.gamma_out));
        mx1 = max(max(color1.r, color1.g), color1.b) + 0.000000000001;
        float mx2 = max(max(color2.r, color2.g), color2.b);
        color1 *= mx2 / mx1;
    }
    FragColor = vec4(color1, 1.);
}

vec4 hook() {
    vertex_main();
    fragment_main();
    return FragColor;
}