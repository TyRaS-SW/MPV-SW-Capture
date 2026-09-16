#include "audio_core.h"
#include <cassert>
#include <cstdio>
#include <limits>
int main() {
    unsigned char bytes[4];
    for (unsigned bits : {16, 24, 32}) for (float value : {-1.f, -.5f, 0.f, .5f, 1.f}) {
        msc::encode(bytes, value, bits, false);
        assert(std::abs(msc::decode(bytes, bits, false) - value) < .00004);
    }
    msc::encode(bytes, 5, 32, true); assert(msc::decode(bytes, 32, true) == 1);
    float nan = std::numeric_limits<float>::quiet_NaN(); std::memcpy(bytes, &nan, 4);
    assert(msc::decode(bytes, 32, true) == 0);
    msc::Ring ring(4); msc::Stereo v;
    assert(!ring.read(1, v));
    for (int n = 0; n < 5; ++n) ring.push({float(n), float(-n)});
    assert(ring.size() == 4 && ring.dropped == 1);
    assert(ring.read(.5, v) && v.left == 1 && v.right == -1);
    assert(ring.read(.5, v) && v.left == 1.5 && v.right == -1.5);
    assert(ring.read(2, v) && v.left == 2);
    assert(!ring.read(1, v));
    ring.trim(0); assert(ring.size() == 0);
    msc::Ring rate(48000);
    for (int n = 0; n < 48000; ++n) rate.push({.25f, -.25f});
    int outputs = 0;
    while (rate.read(48000.0 / 44100, v)) { assert(std::abs(v.left - .25) < .00001); ++outputs; }
    assert(outputs >= 44098 && outputs <= 44100);
    puts("PASS: PCM/float conversion, clipping, NaN, bounded queue, interpolation, underrun and rate conversion");
}
