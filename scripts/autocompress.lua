-- autocompress.lua - For MPV-SW-Capture - By TyRaS-SW

local mp = require "mp"
local utils = require "mp.utils"

-- Default language (change to "es" for Spanish)
local current_lang = "en"  -- "en" or "es"

local is_recording = false
local is_processing = false
local rec_timer = nil
local audio_async_id = nil
local merge_async_id = nil
local record_osd_timer = nil
local record_start_time = nil
local record_target_time = nil

local extra_capture_seconds = 3.0
local finalize_delay_seconds = 0.5
local post_kill_delay_seconds = 0.5

local function get_cwd()
    local dir = mp.get_property("working-directory")
    if dir and dir ~= "" then
        return dir
    end

    local str = debug.getinfo(1, "S").source:sub(2)
    local script_dir = str:match("(.*[/\\])") or ""
    local parent_dir = script_dir:gsub("scripts[\\/]?$", ""):gsub("[\\/]?$", "")

    if parent_dir ~= "" then
        return parent_dir
    end

    return "C:\\"
end

local cwd = get_cwd()

local function get_script_path()
    return debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or ""
end

local function load_external_data(filename, default_data)
    local script_dir = get_script_path()
    local file_path = script_dir .. filename
    local chunk = loadfile(file_path)

    if chunk then
        return chunk()
    end

    mp.msg.warn("Could not find " .. filename .. ". Using default values.")
    return default_data
end

local usb3_data = load_external_data("usb3.lua", {
    audio_device = "Interfaz de sonido digital (USB3 Digital Audio)",
    video_device = "USB3 Video"
})

local record_data = load_external_data("record.lua", {
    max_record_time = 120
})

local function update_menu_state(state)
    is_recording = state
    mp.set_property_bool("user-data/is_recording", state)
end

local function fmt_time(sec)
    sec = math.max(0, math.floor(sec or 0))
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02d:%02d", m, s)
end

local function stop_recording_osd()
    if record_osd_timer then
        record_osd_timer:kill()
        record_osd_timer = nil
    end
end

local function start_recording_osd(total)
    stop_recording_osd()
    record_start_time = mp.get_time()
    record_target_time = tonumber(total) or 0

    record_osd_timer = mp.add_periodic_timer(0.2, function()
        if not is_recording then
            stop_recording_osd()
            return
        end

        local elapsed = mp.get_time() - record_start_time
        local total_now = record_target_time or 0

        if elapsed > total_now then
            elapsed = total_now
        end

        local label
        if current_lang == "es" then
            label = "🔴 GRABANDO"
        else
            label = "🔴 RECORDING"
        end
        local txt = string.format("%s %s / %s", label, fmt_time(elapsed), fmt_time(total_now))
        mp.commandv("show-text", txt, "1000")
    end)
end

local function dir_exists(path)
    local info = utils.file_info(path)
    return info and info.is_dir
end

local function ensure_record_dir(path)
    if dir_exists(path) then
        return true
    end

    utils.subprocess({
        args = { "cmd", "/c", "mkdir", path },
        playback_only = false
    })

    return dir_exists(path)
end

local function clean_temporals()
    local record_dir = cwd .. "\\_record"
    os.remove(record_dir .. "\\audio_temporal.wav")
    os.remove(record_dir .. "\\record.mkv")
    mp.msg.verbose("Temporary files cleaned.")
end

local function kill_audio_ffmpeg()
    utils.subprocess({
        args = { "taskkill", "/IM", "ffmpeg.exe", "/F" },
        playback_only = false
    })
    utils.subprocess({
        args = { "taskkill", "/IM", "ffprobe.exe", "/F" },
        playback_only = false
    })
end

local function get_output_path(record_dir)
    local stamp = os.date("%d-%m-%Y_%H%M%S")
    return string.format("%s\\MSC_%s.mp4", record_dir, stamp)
end

local function finalize_and_merge(target_time)
    stop_recording_osd()
    mp.commandv("show-text", "", "1")

    if current_lang == "es" then
        mp.osd_message("Procesando y uniendo...", 3)
    else
        mp.osd_message("Processing and merging...", 3)
    end

    mp.set_property("stream-record", "")

    local record_dir = cwd .. "\\_record"
    local temp_audio = record_dir .. "\\audio_temporal.wav"
    local abs_video = record_dir .. "\\record.mkv"
    local output = get_output_path(record_dir)
    local final_duration = tonumber(target_time) or tonumber(record_data.max_record_time) or 0

    is_processing = true

    if current_lang == "es" then
        mp.commandv("show-text", "⏳ Finalizando grabación de video, ¡espera!", "6000")
    else
        mp.commandv("show-text", "⏳ Finishing Recording Video, please wait!", "6000")
    end

    mp.add_timeout(finalize_delay_seconds, function()
        kill_audio_ffmpeg()

        mp.add_timeout(post_kill_delay_seconds, function()
            merge_async_id = mp.command_native_async({
                name = "subprocess",
                playback_only = false,
                args = {
                    "ffmpeg.exe",
                    "-y",
                    "-i", abs_video,
                    "-i", temp_audio,
                    "-map", "0:v",
                    "-map", "1:a",
                    "-t", string.format("%.3f", final_duration),
                    "-c:v", "libx264",
                    "-preset", "veryfast",
                    "-crf", "23",
                    "-c:a", "aac",
                    "-b:a", "192k",
                    output
                }
            }, function(success, result, err)
                is_processing = false

                if result and result.status == 0 then
                    if current_lang == "es" then
                        mp.commandv("show-text", "✅¡Finalizado!", "2000")
                    else
                        mp.commandv("show-text", "✅Finished!", "2000")
                    end
                    mp.add_timeout(2, clean_temporals)
                else
                    if current_lang == "es" then
                        mp.osd_message("❌ Error al unir la grabación", 3)
                    else
                        mp.osd_message("❌ Error while merging recording", 3)
                    end
                    if err then
                        mp.msg.error("Merge error: " .. tostring(err))
                    end
                end
            end)
        end)
    end)
end

local function stop_recording()
    if not is_recording then
        return
    end

    update_menu_state(false)
    stop_recording_osd()

    if rec_timer then
        rec_timer:kill()
        rec_timer = nil
    end

    finalize_and_merge(record_target_time)
end

mp.register_script_message("toggle-record", function()
    -- ============================
    -- 🔒 BLOCK RECORD IN STREAMER MODE
    -- ============================
    if mp.get_property_number("osd-duration") == 0 then
    return
end

    if is_processing and not is_recording then
        if current_lang == "es" then
            mp.osd_message("⏳ ¡Espera! La grabación anterior aún se está procesando...", 2)
        else
            mp.osd_message("⏳ Wait! Previous recording still processing...", 2)
        end
        return
    end

    if not is_recording then
        update_menu_state(true)

        local record_dir = cwd .. "\\_record"
        local temp_audio = record_dir .. "\\audio_temporal.wav"
        local video_rel_path = "_record\\record.mkv"
        local target_time = tonumber(record_data.max_record_time) or 30
        local capture_time = target_time + extra_capture_seconds

        if not ensure_record_dir(record_dir) then
            update_menu_state(false)
            if current_lang == "es" then
                mp.osd_message("No se pudo crear la carpeta _record", 3)
            else
                mp.osd_message("Could not create _record folder", 3)
            end
            return
        end

        kill_audio_ffmpeg()

        audio_async_id = mp.command_native_async({
            name = "subprocess",
            playback_only = false,
            args = {
                "ffmpeg.exe",
                "-y",
                "-t", string.format("%.3f", capture_time),
                "-f", "dshow",
                "-i", "audio=" .. usb3_data.audio_device,
                "-c:a", "pcm_s16le",
                temp_audio
            }
        }, function(success, result, err)
            if result and result.status ~= 0 then
                mp.msg.error("Audio ffmpeg failed: " .. tostring(result.status))
                if err then
                    mp.msg.error("Audio error: " .. tostring(err))
                end
            end
        end)

        mp.set_property("stream-record", video_rel_path)
        start_recording_osd(target_time)

        if rec_timer then
            rec_timer:kill()
            rec_timer = nil
        end

        rec_timer = mp.add_timeout(capture_time, stop_recording)
    else
        stop_recording()
    end
end)

update_menu_state(false)