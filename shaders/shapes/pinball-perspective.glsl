// Pinball Table Perspective Shape. By TyRaS-SW, 2026
// License: MIT (see LICENSE in the root of this repository)
//!HOOK MAIN
//!BIND MAIN
//!DESC Form - Pinball Table Perspective

// Relative width at bottom and top (0..1)
// 1.0 = full screen width
#define WIDTH_BOTTOM 1.55   // much wider at the bottom
#define WIDTH_TOP    0.75   // noticeably narrower at the top

// Zoom to bring the image closer
#define ZOOM         1.0

// Vertical offset after zoom
//  > 0 moves the image up, < 0 moves it down
#define V_OFFSET     0.0    // try between -0.12 and 0.0

// No extra black side borders
#define SIDE_BORDER  0.0

vec2 warp_screen(vec2 uv_out)
{
    float y = uv_out.y;              // 0 = bottom, 1 = top
    float x = uv_out.x * 2.0 - 1.0;  // -1..1

    // Strong trapezoid: much wider at the bottom than at the top
    float w = mix(WIDTH_TOP, WIDTH_BOTTOM, y);

    // Invert the horizontal deformation to sample from the straight texture
    float x_in = x / w;

    // Zoom and vertical offset give the sensation
    // that the image is tilted towards the viewer
    x_in *= ZOOM;
    float y_in = (y - 0.5) * ZOOM + 0.5 + V_OFFSET;

    vec2 uv_in = vec2(x_in * 0.5 + 0.5, y_in);
    return uv_in;
}

vec4 hook()
{
    if (SIDE_BORDER > 0.0 &&
        (MAIN_pos.x < SIDE_BORDER || MAIN_pos.x > 1.0 - SIDE_BORDER))
        return vec4(0.0);

    vec2 uv = warp_screen(MAIN_pos);

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
        return vec4(0.0);

    return MAIN_tex(uv);
}