-- https://github.com/9beach/mpv-config/blob/master/scripts/on-file-loaded.lua
--
-- This script has two functionalities:
-- 1. Plays even in paused state when a new file is loaded.
-- 2. Shows OSC alwalys when an audio file is loaded.
--
-- Just copy this file to $MPV_HOME/scripts.

local options = require 'mp.options'

local o = {
    audio_osc_always = true,
    play_on_loaded = true,
}

options.read_options(o, "on-file-loaded")

AUDIO_EXTENSIONS = {
    'aiff', 'ape', 'au', 'flac', 'm4a', 'mka', 'mp3', 'oga', 'ogg',
    'ogm', 'opus', 'wav', 'wma'
}

function get_ext(filepath)
  return filepath:match("^.+%.(.+)$")
end

function is_in(element, array)
    for _, v in ipairs(array) do
        if v == element then return true end
    end
    return false
end

mp.register_event("file-loaded", function()
    -- 1. Plays even in paused state when a new file is loaded.
    if o.play_on_loaded == true then
        mp.set_property_bool("pause", false)
    end

    -- 2. Shows OSC alwalys when an audio file is loaded.
    if o.audio_osc_always == true then
        local ext = string.lower(get_ext(mp.get_property("path", "")))
        local visibility = is_in(ext, AUDIO_EXTENSIONS) and "always" or "auto"
        mp.commandv("script-message", "osc-visibility", visibility, "no-osd")
    end
end)
