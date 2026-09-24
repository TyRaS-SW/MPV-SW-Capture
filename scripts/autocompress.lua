-- autocompress.lua - For MPV-SW-Capture - By TyRaS-SW

local mp = require "mp"
local utils = require "mp.utils"

-- -------------------------------------------------------------------------
-- Load osd_messages safely
-- -------------------------------------------------------------------------
local osd
local function get_script_path()
    local info = debug.getinfo(1, "S")
    return info and info.source:match("@?(.*/)") or ""
end

local script_dir = get_script_path()
local osd_path = script_dir .. "osd_messages.lua"

local ok, err = pcall(function()
    local loaded = dofile(osd_path)
    if loaded and type(loaded.get) == "function" and type(loaded.show) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not return a table with get/show functions")
    end
end)

if not ok then
    local defaults = {
        autocompress_recording_label  = "Recording",
        autocompress_finishing_label  = "Finishing...",
        autocompress_done_label       = "Done!",
        autocompress_processing       = "Processing...",
        autocompress_merge_error      = "Error while merging. Check the log.",
        autocompress_wait_processing  = "Please wait, still processing...",
        autocompress_mkdir_fail       = "Could not create the recording folder.",
        autocompress_quit_blocked     = "Recording in progress. Stop recording first.",
        autocompress_emergency_save   = "Emergency save triggered. Merge will complete after close.",
        autocompress_orphans_pending  = "Orphan recording pending recovery. Restart MPV-SW-Capture or clean _record/ before recording.",
    }

    osd = {
        get = function(key) return defaults[key] or key end,
        show = function(key, duration)
            local text = osd.get(key)
            local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
            if osd_duration_ms == 0 then return end
            if duration == nil then duration = osd_duration_ms / 1000 end
            mp.osd_message(text, duration)
        end
    }
    print("autocompress: Using fallback OSD (osd_messages.lua not loaded). Error: " .. tostring(err))
else
    print("autocompress: osd_messages.lua loaded from " .. osd_path)
end

-- -------------------------------------------------------------------------
-- State variables
-- -------------------------------------------------------------------------
local is_recording = false
local is_processing = false
local rec_timer = nil
local audio_async_id = nil
local merge_async_id = nil
local record_osd_timer = nil
local record_start_time = nil
local record_target_time = nil

-- When true, suppress all OSD output for this recording session.
local suppress_osd = false

local function osd_show_text(text, duration)
    if suppress_osd then return end
    mp.commandv("show-text", text, duration)
end

local function osd_show_msg(key, duration)
    if suppress_osd then return end
    osd.show(key, duration)
end

local extra_capture_seconds = 3.0
local finalize_delay_seconds = 0.5
local post_kill_delay_seconds = 0.5

-- Time we wait after ffmpeg exits before checking the output file.
-- Windows can take a few dozen to a few hundred milliseconds to
-- register a freshly-written file in the filesystem metadata (antivirus
-- scan, write-back cache flush, NTFS metadata update). Without this
-- delay, utils.file_info() sometimes returns nil for a file that was
-- actually written correctly.
local POST_MERGE_VERIFY_DELAY = 0.5

-- Minimum size (bytes) for the output to be considered valid. 1 KB is
-- well above an empty / header-only MP4 and well below any realistic
-- capture clip, no matter how short.
local MIN_VALID_OUTPUT_BYTES = 1024

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

local function get_script_path_full()
    return debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or ""
end

local function load_external_data(filename, default_data)
    local script_dir = get_script_path_full()
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

-- -------------------------------------------------------------------------
-- Utility functions
-- -------------------------------------------------------------------------
local function update_menu_state(state)
    is_recording = state
    mp.set_property_bool("user-data/is_recording", state)
end

local function set_processing_state(state)
    is_processing = state
    mp.set_property_bool("user-data/is_processing", state)
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

    mp.set_property_number("user-data/record_target_seconds", record_target_time)
    mp.set_property_number("user-data/record_elapsed_seconds", 0)

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

        mp.set_property_number("user-data/record_elapsed_seconds", elapsed)

        local label = osd.get("autocompress_recording_label")
        local txt = string.format("%s %s / %s", label, fmt_time(elapsed), fmt_time(total_now))
        osd_show_text(txt, "1000")
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

-- Non-blocking variant used during shutdown: we cannot wait for the
-- process to finish, so fire and forget.
local function kill_audio_ffmpeg_detached()
    utils.subprocess_detached({
        args = { "taskkill", "/IM", "ffmpeg.exe", "/F" }
    })
    utils.subprocess_detached({
        args = { "taskkill", "/IM", "ffprobe.exe", "/F" }
    })
end

local function get_output_path(record_dir)
    local stamp = os.date("%d-%m-%Y_%H%M%S")
    return string.format("%s\\MSC_%s.mp4", record_dir, stamp)
end

-- Decide whether a finished ffmpeg run produced a valid output file.
-- Order of preference:
--   1. ffmpeg exited with code 0 -> definitely success.
--   2. The output file exists on disk with a plausible size -> success,
--      even if ffmpeg reported a non-zero exit code (this happens on
--      harmless warnings like DTS jitter, and the file is fine).
--   3. Otherwise -> failure.
--
-- Callers should invoke this after POST_MERGE_VERIFY_DELAY seconds to
-- give Windows time to register the file metadata.
local function merge_succeeded(result, output_path)
    if result and result.status == 0 then
        return true
    end
    local info = utils.file_info(output_path)
    if info and info.size and info.size >= MIN_VALID_OUTPUT_BYTES then
        mp.msg.warn(string.format(
            "Merge reported failure (status=%s) but output exists (%d bytes). Treating as success.",
            tostring(result and result.status), info.size))
        return true
    end
    if info then
        mp.msg.warn(string.format(
            "Merge output exists but is too small (%d bytes, need %d). Treating as failure.",
            info.size or 0, MIN_VALID_OUTPUT_BYTES))
    else
        mp.msg.warn("Merge output not found at: " .. output_path)
    end
    return false
end

-- -------------------------------------------------------------------------
-- Orphan detection helpers
-- -------------------------------------------------------------------------
-- Returns true only when a complete (video + audio) pair is present,
-- either in "fresh" form (record.mkv + audio_temporal.wav) or in
-- "renamed" form (record_orphan_<stamp>.mkv + audio_temporal_orphan_<stamp>.wav).
--
-- Lone files (video without audio, or audio without video) do NOT count
-- as pending orphans: there is nothing to recover from them, and
-- collect_orphans() will delete them on the next recovery pass. Keeping
-- them out of this check avoids blocking a new recording for a state
-- that the recovery cannot actually fix.
local function has_pending_orphans()
    local record_dir = cwd .. "\\_record"

    -- Fresh pair: both halves present.
    local gv = utils.file_info(record_dir .. "\\record.mkv")
    local ga = utils.file_info(record_dir .. "\\audio_temporal.wav")
    if gv and ga and gv.size > 0 and ga.size > 0 then
        return true
    end

    -- Renamed pairs: both halves present for the same stamp.
    local files = utils.readdir(record_dir, "files")
    if files then
        local seen_v = {}
        local seen_a = {}
        for _, name in ipairs(files) do
            local stamp_v = name:match("^record_orphan_(.+)%.mkv$")
            if stamp_v then seen_v[stamp_v] = true end
            local stamp_a = name:match("^audio_temporal_orphan_(.+)%.wav$")
            if stamp_a then seen_a[stamp_a] = true end
        end
        for stamp, _ in pairs(seen_v) do
            if seen_a[stamp] then return true end
        end
    end

    return false
end

-- -------------------------------------------------------------------------
-- Finalize and merge (for a normal, just-finished recording)
-- -------------------------------------------------------------------------
local function finalize_and_merge(target_time)
    stop_recording_osd()
    osd_show_text("", "1")

    osd_show_msg("autocompress_processing", 3)

    mp.set_property("stream-record", "")

    local record_dir = cwd .. "\\_record"
    local temp_audio = record_dir .. "\\audio_temporal.wav"
    local abs_video = record_dir .. "\\record.mkv"
    local output = get_output_path(record_dir)
    local final_duration = tonumber(target_time) or tonumber(record_data.max_record_time) or 0

    set_processing_state(true)

    local finishing_label = osd.get("autocompress_finishing_label")
    osd_show_text(finishing_label, "6000")

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
                set_processing_state(false)

                mp.add_timeout(POST_MERGE_VERIFY_DELAY, function()
                    if merge_succeeded(result, output) then
                        local done_label = osd.get("autocompress_done_label")
                        osd_show_text(done_label, "2000")
                        mp.add_timeout(2, clean_temporals)
                    else
                        osd_show_msg("autocompress_merge_error", 3)
                        if err then
                            mp.msg.error("Merge error: " .. tostring(err))
                        end
                        if result and result.status then
                            mp.msg.error("Merge status: " .. tostring(result.status))
                        end
                    end
                end)
            end)
        end)
    end)
end

-- -------------------------------------------------------------------------
-- Stop recording
-- -------------------------------------------------------------------------
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

-- -------------------------------------------------------------------------
-- Toggle record (shared implementation)
-- -------------------------------------------------------------------------
local function do_toggle_record_inner()
    if is_processing and not is_recording then
        osd_show_msg("autocompress_wait_processing", 2)
        return
    end

    if not is_recording then
        if has_pending_orphans() then
            osd_show_msg("autocompress_orphans_pending", 4)
            return
        end

        update_menu_state(true)

        local record_dir = cwd .. "\\_record"
        local temp_audio = record_dir .. "\\audio_temporal.wav"
        local video_rel_path = "_record\\record.mkv"
        local target_time = tonumber(record_data.max_record_time) or 30
        local capture_time = target_time + extra_capture_seconds

        if not ensure_record_dir(record_dir) then
            update_menu_state(false)
            osd_show_msg("autocompress_mkdir_fail", 3)
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
end

mp.register_script_message("toggle-record", function()
    if mp.get_property_number("osd-duration") == 0 then
        return
    end
    suppress_osd = false
    do_toggle_record_inner()
end)

mp.register_script_message("force-toggle-record", function()
    suppress_osd = (mp.get_property_number("osd-duration") == 0)
    do_toggle_record_inner()
end)

-- -------------------------------------------------------------------------
-- Quit protection
-- -------------------------------------------------------------------------
local function safe_quit()
    if is_recording or is_processing then
        osd_show_msg("autocompress_quit_blocked", 2)
        return
    end
    mp.commandv("quit")
end

mp.add_forced_key_binding("q",        "ac_quit_q",     safe_quit)
mp.add_forced_key_binding("Ctrl+q",   "ac_quit_ctrlq", safe_quit)
mp.add_forced_key_binding("CLOSE_WIN","ac_quit_close", safe_quit)

mp.register_event("shutdown", function()
    if not (is_recording or is_processing) then
        return
    end

    mp.msg.warn("Shutdown during recording/processing. Attempting emergency save.")

    pcall(function() mp.set_property("stream-record", "") end)
    kill_audio_ffmpeg_detached()

    local record_dir = cwd .. "\\_record"
    local temp_audio = record_dir .. "\\audio_temporal.wav"
    local abs_video = record_dir .. "\\record.mkv"
    local output = get_output_path(record_dir)

    local info_video = utils.file_info(abs_video)
    local info_audio = utils.file_info(temp_audio)

    if info_video and info_audio
       and info_video.size > 0 and info_audio.size > 0 then
        local function ps_quote(s) return "'" .. s:gsub("'", "''") .. "'" end

        local ps_cmd = string.format(
            "Start-Sleep -Seconds 2; " ..
            "if ((Test-Path %s) -and (Test-Path %s)) { " ..
            "& ffmpeg.exe -y -i %s -i %s -map 0:v -map 1:a " ..
            "-c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 192k %s; " ..
            "if ($LASTEXITCODE -eq 0) { " ..
            "Remove-Item %s -Force -ErrorAction SilentlyContinue; " ..
            "Remove-Item %s -Force -ErrorAction SilentlyContinue } }",
            ps_quote(abs_video), ps_quote(temp_audio),
            ps_quote(abs_video), ps_quote(temp_audio),
            ps_quote(output),
            ps_quote(abs_video), ps_quote(temp_audio))

        utils.subprocess_detached({
            args = {
                "powershell.exe",
                "-NoProfile",
                "-WindowStyle", "Hidden",
                "-Command", ps_cmd
            }
        })

        osd_show_msg("autocompress_emergency_save", 3)
    else
        mp.msg.warn("Emergency save skipped: temp files missing or empty.")
    end
end)

-- -------------------------------------------------------------------------
-- Recovery of orphaned temp files on startup (silent)
-- -------------------------------------------------------------------------
-- Runs on every mpv launch with a media file loaded. Two categories:
--
--   1. "Fresh" orphans: record.mkv + audio_temporal.wav, left behind by
--      a hard crash (taskkill /F, power loss, OS crash). Renamed to
--      record_orphan_<stamp>.mkv / audio_temporal_orphan_<stamp>.wav
--      so a future recording cannot overwrite them.
--
--   2. "Renamed" orphans: record_orphan_*.mkv + audio_temporal_orphan_*.wav
--      left behind by a previous recovery that did not complete.
--
-- Silent operation: no OSD messages are shown for success or failure.
-- The user should not be interrupted by background housekeeping. Only
-- the log (mp.msg) records what happened, in case the user needs to
-- diagnose something.
--
-- Each complete pair gets exactly one merge attempt. If it fails, the
-- pair is deleted immediately along with any partial .mp4. Lone files
-- (a video without its audio, or an audio without its video) are
-- deleted outright: there is nothing to recover from them, and leaving
-- them around would accumulate indefinitely. _record/ always ends up
-- in a consistent state: it either contains pairs currently being
-- processed, or nothing.
--
-- Output naming uses get_output_path(), the same MSC_<date>_<time>.mp4
-- scheme as a normal recording, so a recovered file is indistinguish-
-- able from a fresh one.
--
-- Guard: skip when no media file is loaded (tool launcher hosts spin up
-- an mpv instance with no video and quit within ~1s).
local function collect_orphans()
    local record_dir = cwd .. "\\_record"
    local queue = {}

    -- --- Fresh orphans: rename the pair if both halves are present ---
    local fresh_v = record_dir .. "\\record.mkv"
    local fresh_a = record_dir .. "\\audio_temporal.wav"
    local iv = utils.file_info(fresh_v)
    local ia = utils.file_info(fresh_a)

    if iv and ia and iv.size > 0 and ia.size > 0 then
        -- Complete pair: rename both halves and enqueue.
        local stamp = os.date("%d-%m-%Y_%H%M%S")
        local rv = record_dir .. "\\record_orphan_" .. stamp .. ".mkv"
        local ra = record_dir .. "\\audio_temporal_orphan_" .. stamp .. ".wav"
        if os.rename(fresh_v, rv) and os.rename(fresh_a, ra) then
            queue[#queue + 1] = { video = rv, audio = ra, stamp = stamp }
        else
            mp.msg.warn("Recovery: could not rename fresh orphan pair.")
        end
    else
        -- Any fresh half without its partner is unusable. Delete it so
        -- it does not stay on disk forever.
        if iv then
            mp.msg.warn("Recovery: deleting lone fresh video record.mkv")
            os.remove(fresh_v)
        end
        if ia then
            mp.msg.warn("Recovery: deleting lone fresh audio audio_temporal.wav")
            os.remove(fresh_a)
        end
    end

    -- --- Renamed orphans: process complete pairs, delete leftovers ---
    local files = utils.readdir(record_dir, "files")
    if files then
        local seen_v = {}
        local seen_a = {}

        for _, name in ipairs(files) do
            local stamp_v = name:match("^record_orphan_(.+)%.mkv$")
            if stamp_v then seen_v[stamp_v] = true end
            local stamp_a = name:match("^audio_temporal_orphan_(.+)%.wav$")
            if stamp_a then seen_a[stamp_a] = true end
        end

        -- Complete pairs: enqueue.
        for stamp, _ in pairs(seen_v) do
            if seen_a[stamp] then
                local rv = record_dir .. "\\record_orphan_" .. stamp .. ".mkv"
                local ra = record_dir .. "\\audio_temporal_orphan_" .. stamp .. ".wav"
                local iv2 = utils.file_info(rv)
                local ia2 = utils.file_info(ra)
                if iv2 and ia2 and iv2.size > 0 and ia2.size > 0 then
                    queue[#queue + 1] = { video = rv, audio = ra, stamp = stamp }
                else
                    mp.msg.warn("Recovery: deleting incomplete orphan pair " .. stamp)
                    os.remove(rv)
                    os.remove(ra)
                end
            else
                -- Video without its audio partner: delete.
                mp.msg.warn("Recovery: deleting lone orphan video " .. stamp)
                os.remove(record_dir .. "\\record_orphan_" .. stamp .. ".mkv")
            end
        end

        -- Audio without its video partner: delete.
        for stamp, _ in pairs(seen_a) do
            if not seen_v[stamp] then
                mp.msg.warn("Recovery: deleting lone orphan audio " .. stamp)
                os.remove(record_dir .. "\\audio_temporal_orphan_" .. stamp .. ".wav")
            end
        end
    end

    return queue
end

local function process_orphan_queue(queue, index)
    if index > #queue then
        mp.msg.info("Recovery: queue processed (" .. #queue .. " entries).")
        return
    end

    local entry = queue[index]
    local record_dir = cwd .. "\\_record"
    local output = get_output_path(record_dir)

    mp.msg.warn("Recovery: processing " .. entry.video)

    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        args = {
            "ffmpeg.exe",
            "-y",
            "-i", entry.video,
            "-i", entry.audio,
            "-map", "0:v",
            "-map", "1:a",
            "-c:v", "libx264",
            "-preset", "veryfast",
            "-crf", "23",
            "-c:a", "aac",
            "-b:a", "192k",
            output
        }
    }, function(success, result, err)
        mp.add_timeout(POST_MERGE_VERIFY_DELAY, function()
            if merge_succeeded(result, output) then
                os.remove(entry.video)
                os.remove(entry.audio)
                mp.msg.info("Recovery: merged to " .. output)
            else
                os.remove(output)
                os.remove(entry.video)
                os.remove(entry.audio)
                mp.msg.error("Recovery: merge failed for " .. entry.stamp .. ". Files deleted.")
                if err then mp.msg.error("Recovery error: " .. tostring(err)) end
                if result and result.status then
                    mp.msg.error("Recovery status: " .. tostring(result.status))
                end
            end

            process_orphan_queue(queue, index + 1)
        end)
    end)
end

local function recover_orphaned_recording(attempt)
    attempt = attempt or 1

    local path = mp.get_property("path")
    if not path or path == "" then
        if attempt <= 3 then
            mp.add_timeout(1.0, function() recover_orphaned_recording(attempt + 1) end)
        else
            mp.msg.info("Recovery skipped: no media file loaded after 3 retries.")
        end
        return
    end

    local queue = collect_orphans()
    if #queue == 0 then
        return
    end

    process_orphan_queue(queue, 1)
end

mp.add_timeout(2.0, function() recover_orphaned_recording(1) end)

update_menu_state(false)
set_processing_state(false)