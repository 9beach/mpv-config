--[[
https://github.com/9beach/mpv-config/blob/master/scripts/on-file-loaded.lua

This script provides the functions below:

* Plays even in paused state when a new file is loaded.
* Shows OSC alwalys when an audio file is loaded.
* Sets the geometry a value when an audio file is loaded.
]]

local options = require 'mp.options'
local msg = require 'mp.msg'

local o = {
    -- Plays even in paused state when a new file is loaded.
    play_on_loaded = true,
    -- Shows OSC alwalys when an audio file is loaded.
    osc_always_on_audio = true,
}

options.read_options(o, "on-file-loaded")

AUDIO_EXTENSIONS = {
    'aiff', 'ape', 'au', 'flac', 'm4a', 'mka', 'mp3', 'oga', 'ogg',
    'ogm', 'opus', 'wav', 'wma'
}

function is_in(element, array)
    for _, v in ipairs(array) do
        if v == element then return true end
    end
    return false
end

function is_audio_file()
    local path = mp.get_property("path", "")

    local ext = path:match("^.+%.(.+)$")
    if (ext ~= nil) then
        return is_in(string.lower(ext), AUDIO_EXTENSIONS)
    end

    return false
end

-- Shows OSC alwalys when an audio file is loaded.
function change_osc_visibility(is_audio)
    local v = is_audio and "always" or "auto"

    mp.commandv("script-message", "osc-visibility", v, "no-osd")
    mp.commandv("set", "options/osd-bar", (is_audio and "no" or "yes"))
end

mp.register_event("file-loaded", function()
    -- Plays even in paused state when a new file is loaded.
    if o.play_on_loaded == true then
        mp.set_property_bool("pause", false)
    end

    local is_audio = is_audio_file()

    -- Shows OSC alwalys when an audio file is loaded.
    change_osc_visibility(is_audio)
end)
