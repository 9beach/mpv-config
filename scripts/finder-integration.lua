--[[
https://github.com/9beach/mpv-config/blob/master/scripts/finder-integration.lua

This script provides two script messages:
1. `reveal-in-finder` runs explorer.exe/Finder.app/Nautilus with playing file
   selected. If you want to reveal playing file in explorer.exe, it will help
   you.
2. `touch-file` changes the mdate of playing file to current time. If you want
   to mark playing file to delete later or do something else with, it will help
   you.

To invoke these messages, copy this script to `$MPV_HOME/scripts`, and add the
lines below to `$MPV_HOME/input.conf`.

```
CTRL+f              script-message reveal-in-finder
CTRL+x              script-message touch-file
META+f              script-message reveal-in-finder
META+x              script-message touch-file
```
]]

local mp = require 'mp'
local msg = require 'mp.msg'
local options = require 'mp.options'
local utils = require 'mp.utils'

local o = {
    mac_finder = '["open", "-R"]',
    windows_finder = '["explorer.exe", "/select,"]',
    linux_finder = '["nautilus"]', -- Not tested yet
}

options.read_options(o, "finder-integration")

function update_options()
    if os.getenv('windir') ~= nil then
        o.os = 'windows'
        o.finder = utils.parse_json(o.windows_finder)
    elseif os.execute '[ $(uname) = "Darwin" ]' == 0 then
        o.os = 'mac'
        o.finder = utils.parse_json(o.mac_finder)
    else
        o.os = 'linux'
        o.finder = utils.parse_json(o.linux_finder)
    end
end

update_options()

function is_local_file(path)
    return path ~= nil and string.find(path, '://') == nil
end

mp.register_script_message('reveal-in-finder', function()
    local path = mp.get_property_native('path')

    if not is_local_file(path) then return end

    if o.os == 'windows' then path = string.gsub(path, '/', '\\') end

    local my_finder = o.finder
    my_finder[#my_finder+1] = path

    mp.command_native( {name='subprocess', args=my_finder} )
end)

function touch(path)
    local cmd = nil

    if o.os == 'windows' then
        cmd = {
            'powershell',
            '-command',
            '(Get-Item "'..path..'").LastWriteTime=(Get-Date)'
        }
    else
        cmd = {'touch', path}
    end

    return mp.command_native( {name='subprocess', args=cmd} )
end

mp.register_script_message('touch-file', function()
    local path = mp.get_property_native('path')

    if not is_local_file(path) then return end

    local r = touch(path)
    if r.status == 0 then
        mp.osd_message('Touched "'..path..'"')
    else
        mp.osd_message('Failed to touch "'..path..'"')
    end
end)
