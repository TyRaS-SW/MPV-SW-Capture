// Experimental independent WASAPI capture/render engine hosted by MPV.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#define MPV_CPLUGIN_DYNAMIC_SYM
#include <windows.h>
#include <audioclient.h>
#include <audiopolicy.h>
#include <mmdeviceapi.h>
#include <initguid.h>
#include <functiondiscoverykeys_devpkey.h>
#include <ksmedia.h>
#include <avrt.h>
#include <atomic>
#include <mutex>
#include <string>
#include <thread>
#include <stdexcept>
#include <cstdio>
#include "vendor/mpv/client.h"
#include "audio_core.h"

template<class T> struct Com {
    T* p = nullptr;
    ~Com() { if (p) p->Release(); }
    T* operator->() const { return p; }
    T** out() { if (p) p->Release(); p = nullptr; return &p; }
};
struct Event {
    HANDLE h;
    explicit Event(bool manual = false) : h(CreateEventW(nullptr, manual, FALSE, nullptr)) { if (!h) throw std::runtime_error("CreateEvent failed"); }
    ~Event() { CloseHandle(h); }
};
static void check(HRESULT hr, const char* what) {
    if (FAILED(hr)) { char buf[256]; snprintf(buf, sizeof(buf), "%s (0x%08lx)", what, (unsigned long)hr); throw std::runtime_error(buf); }
}
static std::wstring wide(const std::string& s) {
    int n = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, s.c_str(), -1, nullptr, 0);
    if (!n) throw std::runtime_error("Invalid UTF-8 capture device name");
    std::wstring w(n, 0); MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, w.data(), n); w.resize(n - 1); return w;
}
struct Format {
    WAVEFORMATEX* p = nullptr;
    bool floating = false;
    ~Format() { CoTaskMemFree(p); }
    void validate() {
        WORD tag = p->wFormatTag;
        if (tag == WAVE_FORMAT_EXTENSIBLE && p->cbSize >= 22) {
            auto ext = reinterpret_cast<WAVEFORMATEXTENSIBLE*>(p);
            if (IsEqualGUID(ext->SubFormat, KSDATAFORMAT_SUBTYPE_IEEE_FLOAT)) tag = WAVE_FORMAT_IEEE_FLOAT;
            else if (IsEqualGUID(ext->SubFormat, KSDATAFORMAT_SUBTYPE_PCM)) tag = WAVE_FORMAT_PCM;
        }
        floating = tag == WAVE_FORMAT_IEEE_FLOAT;
        if ((!floating && tag != WAVE_FORMAT_PCM) || (floating && p->wBitsPerSample != 32)
            || (!floating && p->wBitsPerSample != 16 && p->wBitsPerSample != 24 && p->wBitsPerSample != 32)
            || !p->nChannels || p->nSamplesPerSec < 8000 || p->nSamplesPerSec > 768000
            || p->nBlockAlign != p->nChannels * (p->wBitsPerSample / 8))
        {
            char why[160]; snprintf(why, sizeof(why), "Unsupported mix format: tag=%u subtype=%u bits=%u channels=%u rate=%lu align=%u extra=%u",
                p->wFormatTag, tag, p->wBitsPerSample, p->nChannels, (unsigned long)p->nSamplesPerSec, p->nBlockAlign, p->cbSize);
            throw std::runtime_error(why);
        }
    }
};
struct Engine {
    Event stop{true};
    std::thread thread;
    std::atomic<double> gain{1}, queueMs{0}, peak{0};
    std::atomic<uint64_t> underruns{0}, dropped{0}, captured{0}, rendered{0};
    std::atomic<bool> running{false};
    std::mutex mutex;
    std::string status = "idle", details;
    ~Engine() { halt(); }
    void halt() { SetEvent(stop.h); if (thread.joinable()) thread.join(); }
    void state(std::string s) { std::lock_guard<std::mutex> lock(mutex); status = std::move(s); }
    std::string getStatus() { std::lock_guard<std::mutex> lock(mutex); return status; }
    std::string getDetails() { std::lock_guard<std::mutex> lock(mutex); return details; }
    void start(std::string device) {
        halt(); ResetEvent(stop.h); underruns = 0; dropped = 0; captured = 0; rendered = 0; peak = 0; queueMs = 0;
        state("starting");
        thread = std::thread([this, device] {
            HRESULT init = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
            if (FAILED(init)) { state("error: COM initialization failed"); return; }
            DWORD taskIndex = 0;
            HANDLE priority = AvSetMmThreadCharacteristicsW(L"Audio", &taskIndex);
            try { run(device); } catch (const std::exception& e) { state(std::string("error: ") + e.what()); }
            running = false;
            if (priority) AvRevertMmThreadCharacteristics(priority);
            CoUninitialize();
        });
    }
    static UINT32 initialize(Com<IAudioClient>& client, IMMDevice* endpoint, Format& fmt, HANDLE event) {
        check(endpoint->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, reinterpret_cast<void**>(client.out())), "Activate endpoint");
        check(client->GetMixFormat(&fmt.p), "GetMixFormat"); fmt.validate();
        UINT32 period = 0;
        Com<IAudioClient3> modern;
        HRESULT hr = client->QueryInterface(__uuidof(IAudioClient3), reinterpret_cast<void**>(modern.out()));
        if (SUCCEEDED(hr)) {
            UINT32 def = 0, fundamental = 0, minimum = 0, maximum = 0;
            hr = modern->GetSharedModeEnginePeriod(fmt.p, &def, &fundamental, &minimum, &maximum);
            if (SUCCEEDED(hr)) {
                period = minimum;
                hr = modern->InitializeSharedAudioStream(AUDCLNT_STREAMFLAGS_EVENTCALLBACK, period, fmt.p, nullptr);
            }
        }
        if (FAILED(hr)) {
            // Some drivers reject low-period shared streams. A fresh client
            // avoids reinitializing a partially initialized audio object.
            check(endpoint->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, reinterpret_cast<void**>(client.out())), "Reactivate endpoint");
            check(client->Initialize(AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_EVENTCALLBACK, 0, 0, fmt.p, nullptr), "Initialize shared audio");
            REFERENCE_TIME def = 0; check(client->GetDevicePeriod(&def, nullptr), "GetDevicePeriod");
            period = UINT32(def * fmt.p->nSamplesPerSec / 10000000);
        }
        check(client->SetEventHandle(event), "SetEventHandle"); return period;
    }
    void run(const std::string& name) {
        if (name.empty()) throw std::runtime_error("No capture device configured; run Setup first");
        Com<IMMDeviceEnumerator> enumerator;
        check(CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, __uuidof(IMMDeviceEnumerator), reinterpret_cast<void**>(enumerator.out())), "Create device enumerator");
        Com<IMMDeviceCollection> devices;
        check(enumerator->EnumAudioEndpoints(eCapture, DEVICE_STATE_ACTIVE, devices.out()), "Enumerate capture devices");
        UINT count = 0; check(devices->GetCount(&count), "Get capture device count");
        Com<IMMDevice> input, output;
        auto requested = wide(name);
        for (UINT i = 0; i < count; ++i) {
            Com<IMMDevice> candidate; check(devices->Item(i, candidate.out()), "Read capture device");
            Com<IPropertyStore> properties; check(candidate->OpenPropertyStore(STGM_READ, properties.out()), "Open capture properties");
            PROPVARIANT value; PropVariantInit(&value);
            HRESULT hr = properties->GetValue(PKEY_Device_FriendlyName, &value);
            bool match = SUCCEEDED(hr) && value.vt == VT_LPWSTR && requested == value.pwszVal;
            PropVariantClear(&value);
            LPWSTR id = nullptr;
            if (SUCCEEDED(candidate->GetId(&id))) { match = match || requested == id; CoTaskMemFree(id); }
            if (match) {
                if (input.p) throw std::runtime_error("Multiple capture devices share that name; use a WASAPI endpoint ID");
                input.p = candidate.p; input.p->AddRef();
            }
        }
        if (!input.p) throw std::runtime_error("Configured capture device not found among active WASAPI inputs");
        check(enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia, output.out()), "Get default output");
        Event captureEvent, renderEvent;
        Com<IAudioClient> captureClient, renderClient;
        Format in, out;
        UINT32 capturePeriod = initialize(captureClient, input.p, in, captureEvent.h);
        UINT32 renderPeriod = initialize(renderClient, output.p, out, renderEvent.h);
        Com<IAudioCaptureClient> capture;
        Com<IAudioRenderClient> render;
        check(captureClient->GetService(__uuidof(IAudioCaptureClient), reinterpret_cast<void**>(capture.out())), "Get capture service");
        check(renderClient->GetService(__uuidof(IAudioRenderClient), reinterpret_cast<void**>(render.out())), "Get render service");
        Com<IAudioSessionControl> session;
        if (SUCCEEDED(renderClient->GetService(__uuidof(IAudioSessionControl), reinterpret_cast<void**>(session.out()))))
            session->SetDisplayName(L"MPV-SW-Capture (Audio Plugin)", nullptr);
        DWORD sessionPid = 0;
        Com<IAudioSessionControl2> sessionInfo;
        if (session.p && SUCCEEDED(session->QueryInterface(__uuidof(IAudioSessionControl2), reinterpret_cast<void**>(sessionInfo.out()))))
            sessionInfo->GetProcessId(&sessionPid);
        UINT32 bufferFrames = 0; check(renderClient->GetBufferSize(&bufferFrames), "Get output buffer size");
        const double inputRate = in.p->nSamplesPerSec, outputRate = out.p->nSamplesPerSec;
        const double nominalStep = inputRate / outputRate;
        // Keep roughly one output period queued, not the entire endpoint's
        // allocated buffer (which can be much larger at high sample rates).
        const UINT32 outputTarget = std::min(bufferFrames, renderPeriod + UINT32(outputRate * .002));
        const size_t target = size_t(std::max(inputRate * .012, capturePeriod + renderPeriod * nominalStep));
        msc::Ring ring(size_t(inputRate / 5));
        char info[384];
        snprintf(info, sizeof(info), "pid=%lu session_pid=%lu input=%luHz/%uch output=%luHz/%uch capture_period=%.2fms render_period=%.2fms target_queue=%.2fms",
            GetCurrentProcessId(), sessionPid, (unsigned long)in.p->nSamplesPerSec, in.p->nChannels, (unsigned long)out.p->nSamplesPerSec,
            out.p->nChannels, capturePeriod * 1000 / inputRate, renderPeriod * 1000 / outputRate, target * 1000 / inputRate);
        { std::lock_guard<std::mutex> lock(mutex); details = info; }
        BYTE* initial = nullptr; check(render->GetBuffer(outputTarget, &initial), "Prime render buffer");
        check(render->ReleaseBuffer(outputTarget, AUDCLNT_BUFFERFLAGS_SILENT), "Release prime buffer");
        check(captureClient->Start(), "Start capture");
        struct StopClient { IAudioClient* p; ~StopClient() { p->Stop(); } } stopCapture{captureClient.p};
        check(renderClient->Start(), "Start render");
        StopClient stopRender{renderClient.p};
        running = true; state("running");
        bool primed = false;
        double currentGain = 0;
        HANDLE events[] = {stop.h, captureEvent.h, renderEvent.h};
        ULONGLONG lastCapture = GetTickCount64();
        while (true) {
            DWORD wait = WaitForMultipleObjects(3, events, FALSE, 1000);
            if (wait == WAIT_OBJECT_0) break;
            if (wait == WAIT_FAILED) throw std::runtime_error("Audio event wait failed");
            UINT32 packet = 0;
            check(capture->GetNextPacketSize(&packet), "Get capture packet size");
            while (packet) {
                BYTE* data = nullptr; UINT32 frames = 0; DWORD flags = 0;
                check(capture->GetBuffer(&data, &frames, &flags, nullptr, nullptr), "Read capture packet");
                const unsigned bytes = in.p->wBitsPerSample / 8;
                double blockPeak = 0;
                for (UINT32 f = 0; f < frames; ++f) {
                    msc::Stereo sample;
                    if (!(flags & AUDCLNT_BUFFERFLAGS_SILENT)) {
                        auto frame = data + f * in.p->nBlockAlign;
                        sample.left = msc::decode(frame, in.p->wBitsPerSample, in.floating);
                        sample.right = in.p->nChannels > 1 ? msc::decode(frame + bytes, in.p->wBitsPerSample, in.floating) : sample.left;
                    }
                    blockPeak = std::max(blockPeak, double(std::max(std::abs(sample.left), std::abs(sample.right))));
                    ring.push(sample);
                }
                peak = blockPeak; captured += frames;
                check(capture->ReleaseBuffer(frames), "Release capture packet");
                lastCapture = GetTickCount64();
                check(capture->GetNextPacketSize(&packet), "Get capture packet size");
            }
            if (GetTickCount64() - lastCapture > 5000) throw std::runtime_error("Capture stopped delivering audio; check device and restart audio");
            // Bound latency after stalls. Adjust the resampling ratio gently
            // around the nominal rate to compensate independent device clocks.
            if (ring.size() > target + size_t(inputRate * .030)) ring.trim(target);
            if (!primed && ring.size() >= target) primed = true;
            UINT32 padding = 0; check(renderClient->GetCurrentPadding(&padding), "Get output padding");
            UINT32 frames = padding < outputTarget ? outputTarget - padding : 0;
            if (frames) {
                BYTE* data = nullptr; check(render->GetBuffer(frames, &data), "Get output buffer");
                memset(data, 0, frames * out.p->nBlockAlign);
                double correction = std::clamp((double(ring.size()) - target) / target * .001, -.002, .002);
                double step = nominalStep * (1 + correction);
                const double requestedGain = gain.load();
                const double gainStep = (requestedGain - currentGain) / std::max(1.0, outputRate * .005);
                for (UINT32 f = 0; f < frames; ++f) {
                    msc::Stereo sample;
                    if (primed && !ring.read(step, sample)) { primed = false; ++underruns; }
                    if (std::abs(requestedGain - currentGain) <= std::abs(gainStep)) currentGain = requestedGain;
                    else currentGain += gainStep;
                    auto frame = data + f * out.p->nBlockAlign;
                    if (out.p->nChannels == 1) msc::encode(frame, float((sample.left + sample.right) * .5 * currentGain), out.p->wBitsPerSample, out.floating);
                    else {
                        msc::encode(frame, float(sample.left * currentGain), out.p->wBitsPerSample, out.floating);
                        msc::encode(frame + out.p->wBitsPerSample / 8, float(sample.right * currentGain), out.p->wBitsPerSample, out.floating);
                    }
                }
                check(render->ReleaseBuffer(frames, 0), "Release output buffer"); rendered += frames;
            }
            queueMs = ring.size() * 1000 / inputRate; dropped = ring.dropped;
        }
        state("stopped");
    }
};

static void publish(mpv_handle* mpv, const char* key, const std::string& value) {
    mpv_set_property_string(mpv, key, value.c_str());
}
extern "C" MPV_EXPORT int mpv_open_cplugin(mpv_handle* mpv) {
    try {
        Engine engine;
        mpv_observe_property(mpv, 1, "volume", MPV_FORMAT_DOUBLE);
        mpv_observe_property(mpv, 2, "mute", MPV_FORMAT_FLAG);
        mpv_observe_property(mpv, 3, "volume-gain", MPV_FORMAT_DOUBLE);
        double volume = 100, boostDb = 0; bool muted = false;
        std::string previousStatus, previousDetails;
        ULONGLONG published = 0;
        while (true) {
            mpv_event* event = mpv_wait_event(mpv, .1);
            if (event->event_id == MPV_EVENT_SHUTDOWN) break;
            if (event->event_id == MPV_EVENT_CLIENT_MESSAGE) {
                auto message = static_cast<mpv_event_client_message*>(event->data);
                if (message->num_args == 2 && !strcmp(message->args[0], "msc-audio-start")) engine.start(message->args[1]);
                if (message->num_args == 1 && !strcmp(message->args[0], "msc-audio-stop")) engine.halt();
            }
            if (event->event_id == MPV_EVENT_PROPERTY_CHANGE) {
                auto property = static_cast<mpv_event_property*>(event->data);
                if (property->data) {
                    if (event->reply_userdata == 1) volume = *static_cast<double*>(property->data);
                    if (event->reply_userdata == 2) muted = *static_cast<int*>(property->data) != 0;
                    if (event->reply_userdata == 3) boostDb = *static_cast<double*>(property->data);
                }
                engine.gain = muted ? 0 : std::clamp(volume, 0.0, 100.0) / 100 * std::pow(10, std::clamp(boostDb, 0.0, 12.1) / 20);
            }
            if (GetTickCount64() - published >= 500) {
                auto status = engine.getStatus(), details = engine.getDetails();
                if (status != previousStatus || details != previousDetails) {
                    publish(mpv, "user-data/audio-plugin-status", status);
                    publish(mpv, "user-data/audio-plugin-details", details);
                    std::string text = "[msc_audio] " + status + " " + details;
                    const char* command[] = {"print-text", text.c_str(), nullptr}; mpv_command(mpv, command);
                    if (status.rfind("error:", 0) == 0) {
                        const char* osd[] = {"show-text", text.c_str(), "8000", nullptr}; mpv_command(mpv, osd);
                    }
                    previousStatus = status; previousDetails = details;
                }
                char stats[256]; snprintf(stats, sizeof(stats), "queue=%.2fms underruns=%llu dropped=%llu captured=%llu rendered=%llu peak=%.4f gain=%.4f",
                    engine.queueMs.load(), (unsigned long long)engine.underruns.load(), (unsigned long long)engine.dropped.load(),
                    (unsigned long long)engine.captured.load(), (unsigned long long)engine.rendered.load(), engine.peak.load(), engine.gain.load());
                publish(mpv, "user-data/audio-plugin-stats", stats); published = GetTickCount64();
            }
        }
        engine.halt();
        return 0;
    } catch (const std::exception& e) {
        publish(mpv, "user-data/audio-plugin-status", std::string("error: ") + e.what()); return -1;
    }
}
