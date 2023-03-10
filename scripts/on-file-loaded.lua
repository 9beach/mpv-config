--[[
https://github.com/9beach/mpv-config/blob/master/scripts/on-file-loaded.lua

This script provides the functions below:

* Plays even in paused state when a new file is loaded.
* Shows OSC alwalys when an audio file is loaded.
* Does not show subtitle if lower-case path matches given patterns.
* Does not show subtitle if audio language matches given values.

`watch_later` settings override subtitle visibilities obove.

You can edit the configuration in `script-opts/on-file-loaded.conf`.
]]

local options = require 'mp.options'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = {
    -- Plays even in paused state when a new file is loaded.
    play_on_loaded = true,
    -- Shows OSC alwalys when an audio file is loaded.
    osc_always_on_audio = true,
    -- Does not show subtitle if lower-case path matches given patterns.
    -- Press `v` to toggle sub-visibility.
    hide_sub_if_path_matches = '',
    -- Does not show subtitle if audio language matches given values.
    hide_sub_if_alang_matches = '',
}

options.read_options(o, "on-file-loaded")

if o.hide_sub_if_path_matches ~= nil and o.hide_sub_if_path_matches ~= '' then
    o.hide_sub_if_path_matches = utils.parse_json(o.hide_sub_if_path_matches)
else
    o.hide_sub_if_path_matches = nil
end

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

function is_audio_file(path)
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

    local path = mp.get_property("path", "")

    -- Shows OSC alwalys when an audio file is loaded.
    change_osc_visibility(is_audio_file(path))

    -- `watch_later` settings override `sub-visibility` obove. 
    if 0 ~= mp.get_property_number('time-pos') then
        msg.info('resumed file, sub-visibility check skipped.')
        return
    end

    local sub_visible = true

    -- Does not show subtitle if path matches...
    if o.hide_sub_if_path_matches ~= '' then
        lower_path = string.lower(path)
        for _, pattern in pairs(o.hide_sub_if_path_matches) do
            if string.match(lower_path, pattern) then
                sub_visible = false
                msg.info('sub-visibility set false: "'..
                          path..'"'..' matched pattern "'..pattern..'"')
                break
            end
        end
    end

    -- Does not show subtitle if audio language matches given values.
    local alang = mp.get_property('current-tracks/audio/lang', '')
    if o.hide_sub_if_alang_matches ~= '' and alang ~= '' then
        for lang in o.hide_sub_if_alang_matches:gmatch("[^, ]+") do
            if lang == alang then
                msg.info('sub-visibility set false: alang matches')
                sub_visible = false
                break
            end
        end
    end

    mp.set_property_bool("sub-visibility", sub_visible)
end)
