local mp = require "mp"

local function get_cwd()
local dir = mp.get_property("working-directory")
if dir and dir ~= "" then return dir end

local str = debug.getinfo(1, "S").source:sub(2)
local script_dir = str:match("(.*[/\\\\])") or ""
local parent_dir = script_dir:gsub("scripts[\\\\/]?$", ""):gsub("[\\\\/]?$", "")

if parent_dir ~= "" then return parent_dir end
return "C:\\"
end

local cwd = get_cwd()

local function get_script_path()
    return debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or ""
end

local function load_external_data(filename, default_data)
    local script_dir = get_script_path()
    local file_path = script_dir .. filename   -- search in scripts\
    local chunk = loadfile(file_path)
    if chunk then
        return chunk()
    else
        mp.msg.warn("Could not find " .. filename .. ". Using default values.")
        return default_data
    end
end

local usb3_data = load_external_data("usb3.lua", {
audio_device = "Interfaz de sonido digital (USB3 Digital Audio)",
video_device = "USB3 Video"
})

local record_data = load_external_data("record.lua", {
max_record_time = 120
})

local is_recording = false
local is_processing = false
local rec_timer = nil

local function update_menu_state(state)
is_recording = state
mp.set_property_bool("user-data/is_recording", state)
end

update_menu_state(false)

local function get_script_path()
return debug.getinfo(1, "S").source:sub(2):match("(.*[/\\\\])") or ""
end

local function kill_audio_ffmpeg()
os.execute('taskkill /FI "WINDOWTITLE eq AudioRecorderMPV*" /T /F >nul 2>&1')
os.execute('taskkill /IM ffmpeg.exe /F >nul 2>&1')
os.execute('taskkill /IM ffprobe.exe /F >nul 2>&1')
end

local function clean_temporals()
local record_dir = cwd .. "\\\\_record"
os.remove(record_dir .. "\\\\audio_temporal.wav")
os.remove(record_dir .. "\\\\record.mkv")
mp.msg.verbose("Temporary files cleaned.")
end

local function finalize_and_merge()
mp.commandv("show-text", "", "1")
mp.osd_message("Processing and Merging...", 3)

mp.set_property("stream-record", "")
kill_audio_ffmpeg()

local record_dir = cwd .. "\\\\_record"
local temp_audio = record_dir .. "\\\\audio_temporal.wav"
local abs_video = record_dir .. "\\\\record.mkv"

local script_dir = get_script_path()
local bat_path = script_dir .. "compress_fuse.bat"

local bat_cmd = string.format('start /min "Fusion" cmd /c ""%s" "%s" "%s" "%s""',
bat_path, abs_video, temp_audio, record_dir)

mp.add_timeout(1.5, function()
os.execute(bat_cmd)

is_processing = true
mp.commandv("show-text", "⏳ Finishing Recording Video, please wait!", "6000")

mp.add_timeout(6, function()
mp.commandv("show-text", "✅Finished!", "2000")
is_processing = false
mp.add_timeout(4, clean_temporals)
end)
end)
end

local function stop_recording()
if not is_recording then return end
update_menu_state(false)
if rec_timer then
rec_timer:kill()
rec_timer = nil
end
finalize_and_merge()
end

mp.register_script_message("toggle-record", function()
if is_processing and not is_recording then
mp.osd_message("⏳ Wait! Previous recording still processing...", 2)
return
end

if not is_recording then
update_menu_state(true)
mp.commandv("show-text", "🔴 RECORDING Video + Audio...", "100000000")

local record_dir = cwd .. "\\\\_record"
local temp_audio = record_dir .. "\\\\audio_temporal.wav"
local video_rel_path = "_record\\\\record.mkv"

os.execute('mkdir "' .. record_dir .. '" 2>nul')

-- AUDIO FIRST (0.5s before video) for perfect sync
kill_audio_ffmpeg()
mp.add_timeout(0.5, function()
local audio_cmd = string.format(
'start "AudioRecorderMPV" /min ffmpeg -y -t %s -f dshow -i audio="%s" -c:a pcm_s16le "%s"',
record_data.max_record_time, usb3_data.audio_device, temp_audio)
os.execute(audio_cmd)
end)

-- VIDEO AFTER (compensated sync)
mp.add_timeout(0.5, function()
mp.set_property("stream-record", video_rel_path)
end)

rec_timer = mp.add_timeout(record_data.max_record_time, stop_recording)

else
stop_recording()
end
end)
