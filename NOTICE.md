\# NOTICE



This repository includes shaders taken from and/or derived from third‑party

projects, as well as original shaders authored by TyRaS-SW.



\## 1. Shaders derived from mpv-retro-shaders / libretro / Lottes



The following files are based on shaders from mpv-retro-shaders and

libretro/common-shaders and retain their original licenses and copyright

notices. TyRaS-SW has applied additional fixes and adjustments, which are

documented in the file headers.



\- crt-aperture-windowscale-fixed.glsl  

&#x20; Based on: `crt-aperture.slang`  

&#x20; Origin: mpv-retro-shaders / libretro common-shaders  

&#x20; Notices inside the file:  

&#x20;   "mpv port by the mpv-retro-shaders Contributors (c) 2022"  

&#x20;   "This file includes additional modifications by TyRaS-SW, 2026"



\- crt-hyllian-fix.glsl  

&#x20; Based on: `crt-hyllian.slang`  

&#x20; Origin: mpv-retro-shaders / libretro common-shaders  

&#x20; Notices inside the file:  

&#x20;   "mpv port by the mpv-retro-shaders Contributors (c) 2022"  

&#x20;   "This file includes additional modifications by TyRaS-SW, 2026"



\- crt-lottes-fix.glsl  

&#x20; Based on: CRT shader by Timothy Lottes (public domain / original license)  

&#x20; Port origin: mpv-retro-shaders  

&#x20; Notices inside the file:  

&#x20;   "Original shader by Timothy Lottes (public domain / original license)"  

&#x20;   "mpv port by the mpv-retro-shaders Contributors (c) 2022"  

&#x20;   "This file includes additional modifications by TyRaS-SW, 2026"



\- dot-perfect.glsl  

&#x20; Based on: `dot.slang`  

&#x20; Origin: mpv-retro-shaders / libretro common-shaders  

&#x20; Notices inside the file:  

&#x20;   "mpv port by the mpv-retro-shaders Contributors (c) 2022"  

&#x20;   "This file includes additional modifications by TyRaS-SW, 2026"



\- gizmo-crt-fixed.glsl  

&#x20; Based on: `gizmo-crt.slang`  

&#x20; Origin: mpv-retro-shaders / libretro common-shaders  

&#x20; Notices inside the file:  

&#x20;   "mpv port by the mpv-retro-shaders Contributors (c) 2022"  

&#x20;   "This file includes additional modifications by TyRaS-SW, 2026"





\## 2. Original shaders by TyRaS-SW (inspired but newly implemented)



The following shaders are original works by TyRaS-SW, inspired by existing

CRT curvature/barrel ideas, but implemented as original code. Their headers

state this explicitly, and they are provided under the MIT License unless

otherwise noted in the individual file.



\- crt-curvature-only.glsl  

\- crt-curvature-onlyE.glsl  

\- crt-widebarrel.glsl  

\- crt-widebarrelE.glsl  



As stated in the file headers, for example:  

&#x20; "This file is inspired in CRT Lottes curvature. By TyRaS-SW, 2026"  

&#x20; "This file is inspired in a CRT Barrel Distortion form. By TyRaS-SW, 2026"  



Unless otherwise noted in a specific file, all original code authored by

TyRaS-SW in this repository is provided under the MIT License as specified

in the `LICENSE` file at the root of this project.





\## 3. Third‑party shaders included without modification



The following shaders are third‑party works included in this repository

without modification. They retain their original licenses and authorship.

Please refer to the file headers and/or the linked upstream projects for

the full license terms.



\- Adaptive\_sharpen\_lite\_RT.glsl  

&#x20; Author: bacondither  

&#x20; License: BSD‑3‑Clause style license (see header in this file and the

&#x20;          original LICENSE at  

&#x20;          https://github.com/bacondither/Adaptive-sharpen)  

&#x20; Status: included as‑is, no modifications by TyRaS-SW.



\- Adaptive\_sharpen\_RT.glsl  

&#x20; Author: bacondither  

&#x20; License: see the original LICENSE at:  

&#x20;          https://github.com/bacondither/Adaptive-sharpen/blob/master/LICENSE  

&#x20;          and:  

&#x20;          https://github.com/bacondither/Miscellaneous-shaders/tree/master/Adaptive-sharpen%20-%20DX11  

&#x20; Status: included as‑is, no modifications by TyRaS-SW.



\- AMD\_FSR1\_RT.glsl  

&#x20; Origin: AMD FidelityFX SDK (FSR1)  

&#x20; License: see the original LICENSE at:  

&#x20;          https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/blob/v2.1.0/Kits/FidelityFX/upscalers/fsr3/include/gpu/fsr1/ffx\_fsr1.h  

&#x20; Status: included as‑is, no modifications by TyRaS-SW.



\- KrigBilateral.glsl  

&#x20; Author: Shiandow  

&#x20; License: GNU Lesser General Public License (LGPL), version 3.0 or later  

&#x20;          (see the header in this file).  

&#x20; Status: included as‑is, no modifications by TyRaS-SW.



\- gba.glsl  

&#x20; Description: Port of the `gba-color` shader from hunterk  

&#x20; Original shader: public domain (as stated by the original author)  

&#x20; mpv port copyright:  

&#x20;   "Copyright (c) 2022, The mpv-retro-shaders Contributors"  

&#x20; License: permissive license as stated in the file header  

&#x20;          (permission to use, copy, modify, and/or distribute this software

&#x20;           for any purpose, with or without fee, provided that the above

&#x20;           copyright notice and this permission notice appear in all copies).  

&#x20; Status: included as‑is, no modifications by TyRaS-SW.



\- crt-gdv-mini-ultra-trinitron.glsl  

&#x20; Origin: mpv-libretro / mpv-retro-shaders  

&#x20; Header:  

&#x20;   "Generated by mpv-libretro"  

&#x20; License: same as the original mpv-retro-shaders/common-shaders project  

&#x20;          (permissive; see the original project for full terms).  

&#x20; Status: included as‑is, no modifications by TyRaS-SW.



\- vhs.glsl  

&#x20; Description: VHS shader by hunterk, adapted for mpv by shmup  

&#x20; Header:  

&#x20;   "- VHS shader by hunterk"  

&#x20;   "- Adapted for MPV by shmup"  

&#x20; License: as provided by the original author in the source/distribution  

&#x20;          (see the original repository/thread for details).  

&#x20; Status: included as‑is, no modifications by TyRaS-SW.





\## 4. Mixed licenses and scope of the MIT License



Note: This repository aggregates shaders under different upstream licenses,

including BSD‑style permissive licenses, the GNU Lesser General Public License

(LGPL), and vendor‑specific licenses (e.g., AMD FidelityFX SDK). Each shader

file must be used, modified, and redistributed in compliance with its own

original license as indicated in the file header and/or the referenced

upstream project.



The MIT License in this repository applies only to original code authored by

TyRaS-SW, not to third‑party shaders included here.

