--[[
https://github.com/9beach/mpv-config/blob/master/scripts/on-file-loaded.lua

This script provides the functions below:

* Plays even in paused state when a new file is loaded.
* Shows OSC alwalys when an audio file is loaded.
]]

local options = require 'mp.options'
local msg = require 'mp.msg'

local o = {
    osc_always_on_audio = true,
    play_on_loaded = true,
    visibility_message_again = false,
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

-- Shows OSC alwalys when an audio file is loaded.
function change_osc_visibility()
    local path = mp.get_property("path", "")
    local is_audio = false

    if path ~= nil then
        local ext = get_ext(path)
        if (ext ~= nil) then
            is_audio = is_in(string.lower(ext), AUDIO_EXTENSIONS)
        end
    end

    local v = is_audio and "always" or "auto"
    mp.commandv("script-message", "osc-visibility", v, "no-osd")
    mp.commandv("set", "options/osd-bar", (is_audio and "no" or "yes"))

    return is_audio
end

mp.register_event("file-loaded", function()
    -- Plays even in paused state when a new file is loaded.
    if o.play_on_loaded == true then
        mp.set_property_bool("pause", false)
    end

    -- Shows OSC alwalys when an audio file is loaded.
    if o.osc_always_on_audio == true then
        local is_audio = change_osc_visibility()

        -- Sometimes "osc-visibility" is overwritten by other scripts, so we
        -- need to try again. This will be helpful when running `reload.lua` 
        -- and `modernx.lua`.
        if is_audio and o.visibility_message_again then
            msg.info('sent again script-message')
            mp.add_timeout(1, change_osc_visibility)
        end
    end
end)
