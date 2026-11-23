// Region-aware 5xBRZ for a game embedded in a larger capture/emulator frame.
// Three passes: sample logical game pixels, apply 5xBRZ, composite into source.
// Defaults calibrated approximately from the supplied unfiltered 1920x1080
// screenshot: (301.625,36.625), 1316.5x1008, assuming 256x224 game pixels.
// Different capture sizes, emulator zoom or border settings require new values.
// ACTIVE_* are relative coordinates (0.0 to 1.0) for resolution independence.
// MODE: 0 bypass, 1 reconstructed pixel grid only, 2 5xBRZ.
// Requires mpv vo=gpu-next; disable other enhancement shaders when calibrating.
// Point sampling can recover a clean enlarged grid; it cannot undo prior blur
// or enhancement. xBRZ itself also intentionally rounds pixel-art features.

/*
   Hyllian's xBR-vertex code and texel mapping
   
   Copyright (C) 2011/2016 Hyllian - sergiogdb@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is 
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.

*/ 

// This shader also uses code and/or concepts from xBRZ as it appears
// in the Desmume source code. The license for which is as follows:

// ****************************************************************************
// * This file is part of the HqMAME project. It is distributed under         *
// * GNU General Public License: http://www.gnu.org/licenses/gpl-3.0          *
// * Copyright (C) Zenju (zenju AT gmx DOT de) - All Rights Reserved          *
// *                                                                          *
// * Additionally and as a special exception, the author gives permission     *
// * to link the code of this program with the MAME library (or with modified *
// * versions of MAME that use the same license as MAME), and distribute      *
// * linked combinations including the two. You must obey the GNU General     *
// * Public License in all respects for all of the code used other than MAME. *
// * If you modify this file, you may extend this exception to your version   *
// * of the file, but you are not obligated to do so. If you do not wish to   *
// * do so, delete this exception statement from your version.                *
// ****************************************************************************
// This file includes additional modifications by TyRaS-SW, 2026

//!PARAM ACTIVE_X
//!DESC Left edge (0.0 for cropped)
//!TYPE CONSTANT float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM ACTIVE_Y
//!DESC Top edge (0.0 for cropped)
//!TYPE CONSTANT float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM ACTIVE_W
//!DESC Game area width (1.0 for cropped)
//!TYPE CONSTANT float
//!MINIMUM 0.01
//!MAXIMUM 1.0
1.0

//!PARAM ACTIVE_H
//!DESC Game area height (1.0 for cropped)
//!TYPE CONSTANT float
//!MINIMUM 0.01
//!MAXIMUM 1.0
1.0

//!PARAM GAME_W
//!DESC Original logical game width
//!TYPE CONSTANT int
//!MINIMUM 1
//!MAXIMUM 4096
256

//!PARAM GAME_H
//!DESC Original logical game height
//!TYPE CONSTANT int
//!MINIMUM 1
//!MAXIMUM 4096
224

//!PARAM MODE
//!DESC 0 bypass, 1 logical pixels only, 2 xBRZ
//!TYPE CONSTANT int
//!MINIMUM 0
//!MAXIMUM 2
2

//!PARAM FINAL_FILTER
//!DESC Final fit: 0 nearest, 1 bilinear (smoother noninteger fit)
//!TYPE CONSTANT int
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM NOISE_TOLERANCE
//!DESC Capture-noise deadband in RGB (0 exact, 0.008 about two 8-bit codes)
//!TYPE CONSTANT float
//!MINIMUM 0.0
//!MAXIMUM 0.05
0.008

//!PARAM EQ_THRESHOLD
//!DESC Color equality threshold (lower = stricter)
//!TYPE CONSTANT float
//!MINIMUM 0.01
//!MAXIMUM 1.0
0.1176470588

//!PARAM DOM_THRESHOLD
//!DESC Factor for dominant edge detection
//!TYPE CONSTANT float
//!MINIMUM 1.0
//!MAXIMUM 9.0
3.6

//!PARAM STEEP_THRESHOLD
//!DESC Factor for shallow/steep lines
//!TYPE CONSTANT float
//!MINIMUM 1.0
//!MAXIMUM 9.0
2.2

//!HOOK MAIN
//!BIND HOOKED
//!SAVE XBRZ_GAME
//!WIDTH GAME_W
//!HEIGHT GAME_H
//!DESC 5xBRZ region - recover game pixel grid

vec4 hook() {
    vec2 input_size_px = vec2(1.0) / HOOKED_pt;
    
    // Calculate absolute pixels from relative percentages based on current input size
    vec2 origin = vec2(ACTIVE_X, ACTIVE_Y) * input_size_px;
    vec2 extent = vec2(ACTIVE_W, ACTIVE_H) * input_size_px;
    
    // Ensure we don't go out of bounds
    origin = clamp(origin, vec2(0.0), input_size_px - 1.0);
    extent = clamp(extent, vec2(1.0), input_size_px - origin);

    vec2 grid_size = vec2(float(GAME_W), float(GAME_H));
    vec2 cell = clamp(floor(HOOKED_pos * grid_size), vec2(0.0), grid_size - 1.0);
    vec2 source_pixel = floor(origin + (cell + 0.5) * extent / grid_size + 0.5);
    source_pixel = clamp(source_pixel, origin, origin + extent - 1.0);
    return HOOKED_tex((source_pixel + 0.5) * HOOKED_pt);
}

//!HOOK MAIN
//!BIND XBRZ_GAME
//!SAVE XBRZ_SCALED
//!WIDTH GAME_W 5 *
//!HEIGHT GAME_H 5 *
//!DESC 5xBRZ region - filter logical pixels

// ── Sampling ─────────────────────────────────────────────────────────────────

// Exact nearest-neighbor sampling at logical pixel coordinates
vec3 fetch(vec2 p, vec2 lsz, vec2 stride) {
    return XBRZ_GAME_tex((clamp(p, vec2(0.0), lsz - 1.0) + 0.5) * stride).rgb;
}

// ── Color distance ────────────────────────────────────────────────────────────
float cdist_sq(vec3 A, vec3 B) {
    vec3 d = A - B;
    if (NOISE_TOLERANCE > 0.0 && all(lessThanEqual(abs(d), vec3(NOISE_TOLERANCE))))
        return 0.0;
    const vec3 w = vec3(0.2627, 0.6780, 0.0593);
    float Y  = dot(d, w);
    float Cb = (d.b - Y) * (0.5 / (1.0 - w.b));
    float Cr = (d.r - Y) * (0.5 / (1.0 - w.r));
    return Y*Y + Cb*Cb + Cr*Cr;
}

float cdist(vec3 A, vec3 B) {
    return sqrt(cdist_sq(A, B));
}

bool same(vec3 A, vec3 B) {
    return all(lessThanEqual(abs(A - B), vec3(NOISE_TOLERANCE)));
}

bool eq(vec3 A, vec3 B) {
    return cdist_sq(A, B) < EQ_THRESHOLD * EQ_THRESHOLD;
}

// ── Main hook ────────────────────────────────────────────────────────────────
vec4 hook() {
    vec2 lsz    = XBRZ_GAME_size;
    vec2 stride = vec2(1.0) / lsz;
    vec2 pix    = floor(XBRZ_GAME_pos * lsz);
    vec2 f      = fract(XBRZ_GAME_pos * lsz);

    // 5x5 neighborhood
    // Pixel Mapping:  20|21|22|23|24
    //                 19|06|07|08|09
    //                 18|05|00|01|10
    //                 17|04|03|02|11
    //                 16|15|14|13|12
    vec3 s0  = fetch(pix, lsz, stride);
    vec3 s1  = fetch(pix + vec2( 1, 0), lsz, stride);
    vec3 s2  = fetch(pix + vec2( 1, 1), lsz, stride);
    vec3 s3  = fetch(pix + vec2( 0, 1), lsz, stride);
    vec3 s4  = fetch(pix + vec2(-1, 1), lsz, stride);
    vec3 s5  = fetch(pix + vec2(-1, 0), lsz, stride);
    vec3 s6  = fetch(pix + vec2(-1,-1), lsz, stride);
    vec3 s7  = fetch(pix + vec2( 0,-1), lsz, stride);
    vec3 s8  = fetch(pix + vec2( 1,-1), lsz, stride);
    vec3 s9  = fetch(pix + vec2( 2,-1), lsz, stride);
    vec3 s10 = fetch(pix + vec2( 2, 0), lsz, stride);
    vec3 s11 = fetch(pix + vec2( 2, 1), lsz, stride);
    vec3 s13 = fetch(pix + vec2( 1, 2), lsz, stride);
    vec3 s14 = fetch(pix + vec2( 0, 2), lsz, stride);
    vec3 s15 = fetch(pix + vec2(-1, 2), lsz, stride);
    vec3 s17 = fetch(pix + vec2(-2, 1), lsz, stride);
    vec3 s18 = fetch(pix + vec2(-2, 0), lsz, stride);
    vec3 s19 = fetch(pix + vec2(-2,-1), lsz, stride);
    vec3 s21 = fetch(pix + vec2(-1,-2), lsz, stride);
    vec3 s22 = fetch(pix + vec2( 0,-2), lsz, stride);
    vec3 s23 = fetch(pix + vec2( 1,-2), lsz, stride);

    // ── Corner voting ─────────────────────────────────────────────────────────
    // b0=NW, b1=NE, b2=SE, b3=SW  (0=NONE, 1=NORMAL, 2=DOMINANT)
    int b0 = 0;
    int b1 = 0;
    int b2 = 0;
    int b3 = 0;

    // SE
    if (!((same(s0,s1) && same(s3,s2)) || (same(s0,s3) && same(s1,s2)))) {
        float da = cdist(s4,s0)+cdist(s0,s8)+cdist(s14,s2)+cdist(s2,s10)+4.0*cdist(s3,s1);
        float db = cdist(s5,s3)+cdist(s3,s13)+cdist(s7,s1)+cdist(s1,s11)+4.0*cdist(s0,s2);
        if (da < db && !same(s0,s1) && !same(s0,s3))
            b2 = (DOM_THRESHOLD * da < db) ? 2 : 1;
    }
    // SW
    if (!((same(s5,s0) && same(s4,s3)) || (same(s5,s4) && same(s0,s3)))) {
        float da = cdist(s17,s5)+cdist(s5,s7)+cdist(s15,s3)+cdist(s3,s1)+4.0*cdist(s4,s0);
        float db = cdist(s18,s4)+cdist(s4,s14)+cdist(s6,s0)+cdist(s0,s2)+4.0*cdist(s5,s3);
        if (da > db && !same(s0,s5) && !same(s0,s3))
            b3 = (DOM_THRESHOLD * db < da) ? 2 : 1;
    }
    // NE
    if (!((same(s7,s8) && same(s0,s1)) || (same(s7,s0) && same(s8,s1)))) {
        float da = cdist(s5,s7)+cdist(s7,s23)+cdist(s3,s1)+cdist(s1,s9)+4.0*cdist(s0,s8);
        float db = cdist(s6,s0)+cdist(s0,s2)+cdist(s22,s8)+cdist(s8,s10)+4.0*cdist(s7,s1);
        if (da > db && !same(s0,s7) && !same(s0,s1))
            b1 = (DOM_THRESHOLD * db < da) ? 2 : 1;
    }
    // NW
    if (!((same(s6,s7) && same(s5,s0)) || (same(s6,s5) && same(s7,s0)))) {
        float da = cdist(s18,s6)+cdist(s6,s22)+cdist(s4,s0)+cdist(s0,s8)+4.0*cdist(s5,s7);
        float db = cdist(s19,s5)+cdist(s5,s3)+cdist(s21,s7)+cdist(s7,s1)+4.0*cdist(s6,s0);
        if (da < db && !same(s0,s5) && !same(s0,s7))
            b0 = (DOM_THRESHOLD * da < db) ? 2 : 1;
    }

    // ── dst[] — all initialized to s0, unrolled ───────────────────────────────
    vec3 d0  = s0; vec3 d1  = s0; vec3 d2  = s0; vec3 d3  = s0; vec3 d4  = s0;
    vec3 d5  = s0; vec3 d6  = s0; vec3 d7  = s0; vec3 d8  = s0; vec3 d9  = s0;
    vec3 d10 = s0; vec3 d11 = s0; vec3 d12 = s0; vec3 d13 = s0; vec3 d14 = s0;
    vec3 d15 = s0; vec3 d16 = s0; vec3 d17 = s0; vec3 d18 = s0; vec3 d19 = s0;
    vec3 d20 = s0; vec3 d21 = s0; vec3 d22 = s0; vec3 d23 = s0; vec3 d24 = s0;

    if (b0 != 0 || b1 != 0 || b2 != 0 || b3 != 0) {

        // ── SE (b2) ───────────────────────────────────────────────────────────
        {
            float da = cdist(s1, s4);
            float db = cdist(s3, s8);
            bool sh = (STEEP_THRESHOLD * da <= db) && !same(s0,s4) && !same(s5,s4);
            bool st = (STEEP_THRESHOLD * db <= da) && !same(s0,s8) && !same(s7,s8);
            bool nb = (b2 != 0);
            bool dl = (b2 >= 2) || !(
                (b1 != 0 && !eq(s0,s4)) ||
                (b3 != 0 && !eq(s0,s8)) ||
                (eq(s4,s3) && eq(s3,s2) && eq(s2,s1) && eq(s1,s8) && !eq(s0,s2)));
            vec3 bp = (cdist_sq(s0,s1) <= cdist_sq(s0,s3)) ? s1 : s3;
            float w1 = (nb && dl && st)  ? 0.250 : 0.0;
            float w2 = (nb && dl) ? (sh ? (st ? 2.0/3.0 : 0.750) : (st ? 0.750 : 0.125)) : 0.0;
            float w3 = (nb && dl && sh)  ? 0.250 : 0.0;
            float w9 = (nb && dl && st)  ? 0.750 : 0.0;
            float w10= (nb && dl) ? (st ? 1.0 : (sh ? 0.250 : 0.125)) : 0.0;
            float w11= nb ? (dl ? (!sh && !st ? 0.875 : 1.0) : 0.2306749731) : 0.0;
            float w12= nb ? (dl ? 1.0 : 0.8631434088) : 0.0;
            float w13= nb ? (dl ? (!sh && !st ? 0.875 : 1.0) : 0.2306749731) : 0.0;
            float w14= (nb && dl) ? (sh ? 1.0 : (st ? 0.250 : 0.125)) : 0.0;
            float w15= (nb && dl && sh) ? 0.750 : 0.0;
            float w16= (nb && dl && sh) ? 0.250 : 0.0;
            float w24= (nb && dl && st) ? 0.250 : 0.0;
            d1  = mix(d1,  bp, w1);  d2  = mix(d2,  bp, w2);
            d3  = mix(d3,  bp, w3);  d9  = mix(d9,  bp, w9);
            d10 = mix(d10, bp, w10); d11 = mix(d11, bp, w11);
            d12 = mix(d12, bp, w12); d13 = mix(d13, bp, w13);
            d14 = mix(d14, bp, w14); d15 = mix(d15, bp, w15);
            d16 = mix(d16, bp, w16); d24 = mix(d24, bp, w24);
        }

        // ── NE (b1) ───────────────────────────────────────────────────────────
        {
            float da = cdist(s7, s2);
            float db = cdist(s1, s6);
            bool sh = (STEEP_THRESHOLD * da <= db) && !same(s0,s2) && !same(s3,s2);
            bool st = (STEEP_THRESHOLD * db <= da) && !same(s0,s6) && !same(s5,s6);
            bool nb = (b1 != 0);
            bool dl = (b1 >= 2) || !(
                (b0 != 0 && !eq(s0,s2)) ||
                (b2 != 0 && !eq(s0,s6)) ||
                (eq(s2,s1) && eq(s1,s8) && eq(s8,s7) && eq(s7,s6) && !eq(s0,s8)));
            vec3 bp = (cdist_sq(s0,s7) <= cdist_sq(s0,s1)) ? s7 : s1;
            float w7 = (nb && dl && st) ? 0.250 : 0.0;
            float w8 = (nb && dl) ? (sh ? (st ? 2.0/3.0 : 0.750) : (st ? 0.750 : 0.125)) : 0.0;
            float w1b= (nb && dl && sh) ? 0.250 : 0.0;
            float w21= (nb && dl && st) ? 0.750 : 0.0;
            float w22= (nb && dl) ? (st ? 1.0 : (sh ? 0.250 : 0.125)) : 0.0;
            float w23= nb ? (dl ? (!sh && !st ? 0.875 : 1.0) : 0.2306749731) : 0.0;
            float w24b=nb ? (dl ? 1.0 : 0.8631434088) : 0.0;
            float w9b= nb ? (dl ? (!sh && !st ? 0.875 : 1.0) : 0.2306749731) : 0.0;
            float w10b=(nb && dl) ? (sh ? 1.0 : (st ? 0.250 : 0.125)) : 0.0;
            float w11b=(nb && dl && sh) ? 0.750 : 0.0;
            float w12b=(nb && dl && sh) ? 0.250 : 0.0;
            float w20= (nb && dl && st) ? 0.250 : 0.0;
            d7  = mix(d7,  bp, w7);   d8  = mix(d8,  bp, w8);
            d1  = mix(d1,  bp, w1b);  d21 = mix(d21, bp, w21);
            d22 = mix(d22, bp, w22);  d23 = mix(d23, bp, w23);
            d24 = mix(d24, bp, w24b); d9  = mix(d9,  bp, w9b);
            d10 = mix(d10, bp, w10b); d11 = mix(d11, bp, w11b);
            d12 = mix(d12, bp, w12b); d20 = mix(d20, bp, w20);
        }

        // ── NW (b0) ───────────────────────────────────────────────────────────
        {
            float da = cdist(s5, s8);
            float db = cdist(s7, s4);
            bool sh = (STEEP_THRESHOLD * da <= db) && !same(s0,s8) && !same(s1,s8);
            bool st = (STEEP_THRESHOLD * db <= da) && !same(s0,s4) && !same(s3,s4);
            bool nb = (b0 != 0);
            bool dl = (b0 >= 2) || !(
                (b3 != 0 && !eq(s0,s8)) ||
                (b1 != 0 && !eq(s0,s4)) ||
                (eq(s8,s7) && eq(s7,s6) && eq(s6,s5) && eq(s5,s4) && !eq(s0,s6)));
            vec3 bp = (cdist_sq(s0,s5) <= cdist_sq(s0,s7)) ? s5 : s7;
            float w5 = (nb && dl && st) ? 0.250 : 0.0;
            float w6 = (nb && dl) ? (sh ? (st ? 2.0/3.0 : 0.750) : (st ? 0.750 : 0.125)) : 0.0;
            float w7b= (nb && dl && sh) ? 0.250 : 0.0;
            float w17= (nb && dl && st) ? 0.750 : 0.0;
            float w18= (nb && dl) ? (st ? 1.0 : (sh ? 0.250 : 0.125)) : 0.0;
            float w19= nb ? (dl ? (!sh && !st ? 0.875 : 1.0) : 0.2306749731) : 0.0;
            float w20b=nb ? (dl ? 1.0 : 0.8631434088) : 0.0;
            float w21b=nb ? (dl ? (!sh && !st ? 0.875 : 1.0) : 0.2306749731) : 0.0;
            float w22b=(nb && dl) ? (sh ? 1.0 : (st ? 0.250 : 0.125)) : 0.0;
            float w23b=(nb && dl && sh) ? 0.750 : 0.0;
            float w24c=(nb && dl && sh) ? 0.250 : 0.0;
            float w16b=(nb && dl && st) ? 0.250 : 0.0;
            d5  = mix(d5,  bp, w5);   d6  = mix(d6,  bp, w6);
            d7  = mix(d7,  bp, w7b);  d17 = mix(d17, bp, w17);
            d18 = mix(d18, bp, w18);  d19 = mix(d19, bp, w19);
            d20 = mix(d20, bp, w20b); d21 = mix(d21, bp, w21b);
            d22 = mix(d22, bp, w22b); d23 = mix(d23, bp, w23b);
            d24 = mix(d24, bp, w24c); d16 = mix(d16, bp, w16b);
        }

        // ── SW (b3) ───────────────────────────────────────────────────────────
        {
            float da = cdist(s3, s6);
            float db = cdist(s5, s2);
            bool sh = (STEEP_THRESHOLD * da <= db) && !same(s0,s6) && !same(s7,s6);
            bool st = (STEEP_THRESHOLD * db <= da) && !same(s0,s2) && !same(s1,s2);
            bool nb = (b3 != 0);
            bool dl = (b3 >= 2) || !(
                (b2 != 0 && !eq(s0,s6)) ||
                (b0 != 0 && !eq(s0,s2)) ||
                (eq(s6,s5) && eq(s5,s4) && eq(s4,s3) && eq(s3,s2) && !eq(s0,s4)));
            vec3 bp = (cdist_sq(s0,s3) <= cdist_sq(s0,s5)) ? s3 : s5;
            float w3b= (nb && dl && st) ? 0.250 : 0.0;
            float w4 = (nb && dl) ? (sh ? (st ? 2.0/3.0 : 0.750) : (st ? 0.750 : 0.125)) : 0.0;
            float w5b= (nb && dl && sh) ? 0.250 : 0.0;
            float w13b=(nb && dl && st) ? 0.750 : 0.0;
            float w14b=(nb && dl) ? (st ? 1.0 : (sh ? 0.250 : 0.125)) : 0.0;
            float w15b=nb ? (dl ? (!sh && !st ? 0.875 : 1.0) : 0.2306749731) : 0.0;
            float w16c=nb ? (dl ? 1.0 : 0.8631434088) : 0.0;
            float w17b=nb ? (dl ? (!sh && !st ? 0.875 : 1.0) : 0.2306749731) : 0.0;
            float w18b=(nb && dl) ? (sh ? 1.0 : (st ? 0.250 : 0.125)) : 0.0;
            float w19b=(nb && dl && sh) ? 0.750 : 0.0;
            float w20c=(nb && dl && sh) ? 0.250 : 0.0;
            float w12c=(nb && dl && st) ? 0.250 : 0.0;
            d3  = mix(d3,  bp, w3b);  d4  = mix(d4,  bp, w4);
            d5  = mix(d5,  bp, w5b);  d13 = mix(d13, bp, w13b);
            d14 = mix(d14, bp, w14b); d15 = mix(d15, bp, w15b);
            d16 = mix(d16, bp, w16c); d17 = mix(d17, bp, w17b);
            d18 = mix(d18, bp, w18b); d19 = mix(d19, bp, w19b);
            d20 = mix(d20, bp, w20c); d12 = mix(d12, bp, w12c);
        }
    }

    // ── Final selection ───────────────────────────────────────────────────────
    float fx = f.x;
    float fy = f.y;
    vec3 row0 = mix(d20, mix(mix(d21, d22, step(0.40,fx)), mix(d23, d24, step(0.80,fx)), step(0.60,fx)), step(0.20,fx));
    vec3 row1 = mix(d19, mix(mix(d6,  d7,  step(0.40,fx)), mix(d8,  d9,  step(0.80,fx)), step(0.60,fx)), step(0.20,fx));
    vec3 row2 = mix(d18, mix(mix(d5,  d0,  step(0.40,fx)), mix(d1,  d10, step(0.80,fx)), step(0.60,fx)), step(0.20,fx));
    vec3 row3 = mix(d17, mix(mix(d4,  d3,  step(0.40,fx)), mix(d2,  d11, step(0.80,fx)), step(0.60,fx)), step(0.20,fx));
    vec3 row4 = mix(d16, mix(mix(d15, d14, step(0.40,fx)), mix(d13, d12, step(0.80,fx)), step(0.60,fx)), step(0.20,fx));
    vec3 res  = mix(row0,
                    mix(mix(row1, row2, step(0.40,fy)),
                        mix(row3, row4, step(0.80,fy)),
                        step(0.60,fy)),
                    step(0.20,fy));
    return vec4(res, 1.0);
}

//!HOOK MAIN
//!BIND HOOKED
//!BIND XBRZ_GAME
//!BIND XBRZ_SCALED
//!DESC 5xBRZ region - composite active game area

vec4 hook() {
    vec4 original = HOOKED_tex(HOOKED_pos);
    if (MODE == 0) return original;
    
    vec2 input_size_px = vec2(1.0) / HOOKED_pt;
    
    // Calculate absolute pixels from relative percentages based on current input size
    vec2 origin = vec2(ACTIVE_X, ACTIVE_Y) * input_size_px;
    vec2 extent = vec2(ACTIVE_W, ACTIVE_H) * input_size_px;
    
    // Ensure we don't go out of bounds
    origin = clamp(origin, vec2(0.0), input_size_px - 1.0);
    extent = clamp(extent, vec2(1.0), input_size_px - origin);

    vec2 local = (HOOKED_pos / HOOKED_pt - origin) / extent;
    if (any(lessThan(local, vec2(0.0))) || any(greaterThanEqual(local, vec2(1.0))))
        return original;
    if (MODE == 1) {
        vec2 cell = floor(local * XBRZ_GAME_size);
        return XBRZ_GAME_tex((cell + 0.5) / XBRZ_GAME_size);
    }
    if (FINAL_FILTER == 1) {
        // Explicit four-tap interpolation of the completed 5x image. Sample at
        // texel centres so this is independent of the bound sampler's filter.
        vec2 p = local * XBRZ_SCALED_size - 0.5;
        vec2 base = floor(p);
        vec2 f = fract(p);
        vec2 limit = XBRZ_SCALED_size - 1.0;
        vec2 a = (clamp(base, vec2(0.0), limit) + 0.5) / XBRZ_SCALED_size;
        vec2 b = (clamp(base + vec2(1.0), vec2(0.0), limit) + 0.5) / XBRZ_SCALED_size;
        vec4 top = mix(XBRZ_SCALED_tex(a), XBRZ_SCALED_tex(vec2(b.x,a.y)), f.x);
        vec4 bottom = mix(XBRZ_SCALED_tex(vec2(a.x,b.y)), XBRZ_SCALED_tex(b), f.x);
        return mix(top, bottom, f.y);
    }
    vec2 cell = floor(local * XBRZ_SCALED_size);
    return XBRZ_SCALED_tex((cell + 0.5) / XBRZ_SCALED_size);
}