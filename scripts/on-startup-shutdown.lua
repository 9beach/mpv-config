--[[
https://github.com/9beach/mpv-config/blob/master/scripts/on-startup-shutdown.lua

This script provides the functions below:

* Saves and restores sound volume level

`watch_later` settings override sound volume level above.

You can edit the configuration in `script-opts/on-startup-shutdown.lua`.
]]

local options = require 'mp.options'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = {
    save_and_restore_sound_volume = true,
}

options.read_options(o, "on-startup-shutdown")

if o.save_and_restore_sound_volume == false then return end

local volume_filepath = 
    (os.getenv('APPDATA') or os.getenv('HOME')..'/.config')..'/mpv/.volume'

local volume

local f = io.open(volume_filepath, "r")
if f then
    volume = tonumber(f:read "*a")
    f:close()
end

if volume then
    mp.set_property_native('volume', volume)
end

mp.register_event("shutdown", function()
    local f = io.open(volume_filepath, "w+")
    if f then
        f:write(mp.get_property_native('volume'))
        f:close()
    end
end)
