--[[
https://github.com/9beach/mpv-config/blob/master/scripts/on-startup-shutdown.lua

This script provides the functions below:

- Saves and restores sound volume level automatically.

`watch_later` setting for each file overrides sound volume level above.
So if you change the sound volume level of a file, **mpv** remembers it just
for that file if you resume to play it.

You can edit the configuration in `script-opts/on-startup-shutdown.lua`.
]]

local options = require 'mp.options'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local o = {
    save_and_restore_sound_volume = true,
}

if os.getenv('windir') ~= nil then
    o.platform = 'windows'
elseif os.execute '[ $(uname) = "Darwin" ]' == 0 then
    o.platform = 'darwin'
else
    o.platform = 'linux'
end

options.read_options(o, "on-startup-shutdown")

if o.save_and_restore_sound_volume == false then return end

local volume_filepath = 
    mp.command_native({"expand-path", "~~/"}).."/watch_later/.volume"

local volume

local f = io.open(volume_filepath, "r")
if f then
    volume = tonumber(f:read "*a")
    f:close()
end

if volume then
    mp.set_property_native('volume', volume)
end

function create_dir(dir)
    if utils.readdir(dir) == nil then
        local args
        if o.platform == 'windows' then
            args = {
                'powershell', '-NoProfile', '-Command', 'mkdir',
                ps_quote_string(dir)
            }
        else
            args = {'mkdir', dir}
        end

        local res = utils.subprocess({args=args, cancellable=false})
        return res.status == 0
    else
        return true
    end
end

mp.register_event("shutdown", function()
    create_dir(mp.command_native({"expand-path", "~~/"}).."/watch_later")
    local f = io.open(volume_filepath, "w+")
    if f then
        f:write(mp.get_property_native('volume'))
        f:close()
    end
end)
