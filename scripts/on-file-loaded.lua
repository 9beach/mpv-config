--[[
https://github.com/9beach/mpv-config/blob/master/scripts/on-file-loaded.lua

This script provides the functions below:

* Shows OSC always when an audio file (that is of known audio extensions or 
  has no video) is loaded.
* Plays even in paused state when a new file is loaded.
* Does not show subtitle if lower-case path matches given patterns.
* Does not show subtitle if audio language matches given values.
* Resets **mpv** geometry when an non-audio file (that is not of known audio 
  extensions and has no video) is loaded. With this feature, **mpv** can 
  escape from small rectable when a webm media has video even if `mpv.conf` has 
  settings below.

  ```
  [extension.webm]
  geometry=800x800+100%+100%
  ```

`watch_later` setting for each file overrides subtitle visibilities above.
So if you change the visibility of subtitle in a file, **mpv** remembers it
just for that file if you resume to play it.

You can edit the configuration in `script-opts/on-file-loaded.conf`.
]]

local options = require 'mp.options'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = {
    -- Escapes from small rectable when a webm media has video even if 
    -- `mpv.conf` has settings below.
    --
    -- [extension.webm]
    -- geometry=800x800+100%+100%
    reset_geometry_on_video = true,
    -- Plays even in paused state when a new file is loaded.
    play_on_loaded = true,
    -- Shows OSC alwalys when an audio file is loaded.
    osc_always_on_audio = true,
    -- Does not show subtitle if lower-case path matches given patterns.
    -- Press `v` to toggle sub-visibility.
    hide_sub_if_path_matches = '',
    -- Does not show subtitle if audio language matches given values.
    hide_sub_if_alang_matches = '',
    -- `watch_later` settings override subtitle visibilities obove.
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
    local vid = mp.get_property("vid")
    msg.info('vid: '..vid..' '..path)
    if vid == "no" then return true end

    local ext = path:match("^.+%.(.+)$")
    if (ext ~= nil) then
        return is_in(string.lower(ext), AUDIO_EXTENSIONS)
    end

    return false
end

-- Saves previous states
local show_osd_bar = mp.get_property_bool("options/osd-bar")
local osd_on_seek =  mp.get_property_native("osd-on-seek")
local geometry = mp.get_property_native("geometry")
local autofit = mp.get_property_native("autofit")

-- Shows OSC alwalys when an audio file is loaded.
function change_osc_visibility(is_audio)
    local vosc = is_audio and "always" or "auto"

    mp.commandv("script-message", "osc-visibility", vosc, "no-osd")
    local vosd_bar = (is_audio or not show_osd_bar) and "no" or "yes"
    mp.commandv("set", "options/osd-bar", vosd_bar)
    mp.commandv("set", "osd-on-seek", is_audio and "no" or osd_on_seek)
end

function on_file_loaded()
    -- Plays even in paused state when a new file is loaded.
    if o.play_on_loaded == true then
        mp.set_property_bool("pause", false)
    end

    local path = mp.get_property("path", "")

    -- Shows OSC alwalys when an audio file is loaded.
    local is_audio = is_audio_file(path)

    if o.osc_always_on_audio then
        change_osc_visibility(is_audio)
    end
    if o.reset_geometry_on_video and not is_audio then
        msg.info("reset geometry and autofit: "..autofit)
        mp.set_property_native("autofit", autofit)
        mp.set_property_native("geometry", geometry)
    end

    -- From here till end of the function, checks sub-visibility.
    --
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
                msg.info('sub-visibility set false: audio lang matches')
                sub_visible = false
                break
            end
        end
    end

    mp.set_property_bool("sub-visibility", sub_visible)
end

mp.register_event("file-loaded", on_file_loaded)
