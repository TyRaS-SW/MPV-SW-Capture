#pragma once
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <vector>

namespace msc {
struct Stereo { float left = 0, right = 0; };

inline float decode(const unsigned char* p, unsigned bits, bool floating) {
    if (floating) { float v; std::memcpy(&v, p, 4); return std::isfinite(v) ? v : 0; }
    if (bits == 16) { int16_t v; std::memcpy(&v, p, 2); return v / 32768.0f; }
    if (bits == 24) {
        int32_t v = p[0] | (p[1] << 8) | (p[2] << 16);
        if (v & 0x800000) v -= 0x1000000;
        return v / 8388608.0f;
    }
    int32_t v; std::memcpy(&v, p, 4); return float(v / 2147483648.0);
}
inline void encode(unsigned char* p, float v, unsigned bits, bool floating) {
    v = std::isfinite(v) ? std::clamp(v, -1.0f, 1.0f) : 0;
    if (floating) { std::memcpy(p, &v, 4); return; }
    if (bits == 16) { int16_t n = int16_t(std::clamp(std::llround(v * 32768.0), -32768LL, 32767LL)); std::memcpy(p, &n, 2); }
    else if (bits == 24) {
        int32_t n = int32_t(std::clamp(std::llround(v * 8388608.0), -8388608LL, 8388607LL));
        p[0] = n & 255; p[1] = (n >> 8) & 255; p[2] = (n >> 16) & 255;
    } else { int32_t n = int32_t(std::clamp(std::llround(v * 2147483648.0), -2147483648LL, 2147483647LL)); std::memcpy(p, &n, 4); }
}

// Single audio thread owns this bounded queue. No allocations in push/read.
class Ring {
    std::vector<Stereo> data;
    size_t head = 0, count = 0;
    double phase = 0;
public:
    uint64_t dropped = 0;
    explicit Ring(size_t capacity) : data(std::max(size_t(2), capacity)) {}
    size_t size() const { return count; }
    void trim(size_t keep) {
        if (count > keep) { size_t n = count - keep; head = (head + n) % data.size(); count -= n; dropped += n; phase = 0; }
    }
    void push(Stereo v) {
        if (count == data.size()) trim(count - 1);
        data[(head + count) % data.size()] = v; ++count;
    }
    bool read(double step, Stereo& v) {
        if (!(step > 0) || !std::isfinite(step)) return false;
        size_t advance = size_t(phase + step);
        if (count < 2 || advance >= count) return false;
        auto a = data[head], b = data[(head + 1) % data.size()];
        v = {float(a.left + (b.left - a.left) * phase), float(a.right + (b.right - a.right) * phase)};
        phase += step; phase -= advance;
        head = (head + advance) % data.size(); count -= advance;
        return true;
    }
};
}
