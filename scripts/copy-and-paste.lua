-- https://github.com/9beach/mpv-config/blob/main/scripts/copy-and-paste.lua
--
-- This script gives mpv the capability to copy and paste file paths and URLs.

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local o = {
    linux_copy = 'xclip -silent -selection clipboard -in',
    linux_paste = 'xclip -selection clipboard -o',
    osd_messages = true,
    idle_state_copy_script = 'script-message copy-quote',
    copy_keybind = 'ctrl+c meta+c',
    paste_keybind = 'ctrl+v meta+v',
}

options.read_options(o, "copy-and-paste", function(list) update_opts(list) end)

if os.getenv('windir') ~= nil then
    o.device = 'windows'
elseif os.execute '[ $(uname) = "Darwin" ]' == 0 then
    o.device = 'mac'
else
    o.device = 'linux'
end

function osd_print(text)
    msg.info(text)
    if o.osd_messages == true then mp.osd_message(text) end
end

function bind_keys(keys, name, func, opts)
    if not keys then
        mp.add_forced_key_binding(keys, name, func, opts)
        return
    end

    local i = 0
    for key in string.gmatch(keys, "[^%s]+") do
        i = i + 1
        if i == 1 then 
            mp.add_forced_key_binding(key, name, func, opts)
        else
            mp.add_forced_key_binding(key, name .. i, func, opts)
        end
    end
end

function pipe_read(cmd)
    local f = io.popen(cmd, 'r')
    local s = f:read('*a')
    f:close()
    return s
end

function pipe_write(cmd, text)
    local f = io.popen(cmd, 'w')
    local s = f:write(text)
    f:close()
end

function get_clipboard()
    if o.device == 'linux' then
        return pipe_read(o.linux_paste)
    elseif o.device == 'windows' then
        local script =  [[
        & {
            Trap {
                Write-Error -ErrorRecord $_
                Exit 1
            }
            $clip = Get-Clipboard -Raw -Format Text -TextFormatType UnicodeText
            if (-not $clip) {
                $clip = Get-Clipboard -Raw -Format FileDropList
            }
            $u8clip = [System.Text.Encoding]::UTF8.GetBytes($clip)
            [Console]::OpenStandardOutput().Write($u8clip, 0, $u8clip.Length)
        }
        ]]
        local args = { 'powershell', '-NoProfile', '-Command', script }
        local res = utils.subprocess({args=args, cancellable=false})
        if not res.error and res.status == 0 then
            return res.stdout
        else
            msg.error("There was an error getting clipboard: ")
            msg.error("  Status: "..(res.status or ""))
            msg.error("  Error: "..(res.error or ""))
            msg.error("args: "..utils.to_string(args))
            return ''
        end
    elseif o.device == 'mac' then
        return pipe_read('LC_CTYPE=UTF-8 pbpaste')
    end

    return ''
end

function set_clipboard(text)
    if o.device == 'linux' then
        pipe_write(o.linux_copy, text)
    elseif o.device == 'windows' then
        local clip = '"'..text:gsub('"', "'")..'"'
        local args = {
            'powershell', '-NoProfile', 'Set-Clipboard', '-value', clip
        }
        local res = utils.subprocess({args=args, cancellable=false})
        if res.error then msg.error('paste failed: '..res.error) end
    elseif o.device == 'mac' then
        pipe_write('LC_CTYPE=UTF-8 pbcopy', text)
    end
end

function copy()
   	local path = mp.get_property('path')
    if (path ~= nil) then
        set_clipboard(path)
        osd_print('File path or URL copied')
    elseif (o.idle_state_copy_script ~= '') then
        mp.command(o.idle_state_copy_script)
        osd_print('Copy message sent')
    end
end

function paste()
    clip = get_clipboard()

    if not clip then
        osd_print('Clipboard is empty')
        return
    end

    local i = 0
    for path in clip:gmatch("[^\r\n]+") do
        i = i + 1
        if i == 1 then
            mp.commandv('loadfile', path)
        else
            mp.commandv('loadfile', path, 'append-play')
        end
    end    

    if i == 1 then
        osd_print('Loading ...')
    else
        osd_print('Loading '..tostring(i)..' URLs or files ...')
    end
end

mp.register_event('file-loaded', function()
    -- Only support Youtube seektime
    local path = mp.get_property('path')
    if path then
        osd_print(path)
    end
end)

mp.register_script_message("copy-to-clipboard", function(title, text)
    set_clipboard(text)
    if o.osd_messages == true then
        msg.info(title.." copied: "..text)
        mp.osd_message(title.." copied")
    end
end)

bind_keys(o.copy_keybind, 'copy', copy)
bind_keys(o.paste_keybind, 'paste', paste)
