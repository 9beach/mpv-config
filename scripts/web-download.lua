--[[
https://github.com/9beach/mpv-config/blob/main/scripts/web-download.lua

With this script, you can download media files of **mpv** playlist from web
sites including YouTube, Twitter, Twitch.tv, Naver, Kakao...

You can edit key bindings below in `script-opts/web-download.conf`:

- Downloads currently playing media. (`Ctrl+d, Meta+d`)
- Downloads all media of **mpv** playlist. (`Ctrl+D, Meta+D`)
- Downloads currently playing media as a audio file. (`Ctrl+e, Meta+e`)
- Downloads all media of **mpv** playlist as audio files. (`Ctrl+E, Meta+E`)

To download media files, you need to install
[yt-dlp](https://github.com/yt-dlp/yt-dlp/releases) in your system.
For _Microsoft Windows_ users, just download `yt-dlp.exe` and copy it to
`C:\Windows` or `mpv.exe` directory. For _OSX_ users, run `brew install yt-dlp`.
]]

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local o = {
    -- `~~desktop/` is `$HOME/Desktop`, `~~/' is mpv configuration directory.
    -- Supports `$HOME` for Microsoft Windows also.
    download_dir = '$HOME/Downloads',
    -- If yes, download to `$HOME/Desktop/230319-034313`, or `$HOME/Desktop/`.
    download_to_time_dir = false,
    -- More detailed subtitle download options here.
    download_command = 'yt-dlp --no-mtime --write-sub',
    -- `ba` for 'best audio'. With YouTubes VP9 codec this file will most likely
    -- be .webm or .opus extension. To save the highest quality audio as an 
    -- mp3 file you need to install `ffmpeg` and change below to 
    -- `yt-dlp --no-mtime -f ba -x --audio-format mp3`.
    download_audio_command = 'yt-dlp --no-mtime -f ba',
    linux_download = 'gnome-terminal -e "bash \'$download_script\'"',
    windows_download = 'start cmd /c "$download_script"',
    mac_download = 'osascript -e \'tell application "Terminal"\' -e \'if not application "Terminal" is running then launch\' -e activate -e "do script \\\"bash \'$download_script\'\\\"" -e end',
    -- Keybind for downloading currently playing media.
    download_current_track_keybind = 'Ctrl+d Meta+d',
    -- Keybind for downloading all media of playlist.
    download_playlist_keybind = 'Ctrl+Shift+d Meta+Shift+d',
    -- Keybind for downloading currently playing media as a audio file.
    download_current_track_audio_keybind = 'Ctrl+e Meta+e',
    -- Keybind for downloading all media of playlist as audio files.
    download_playlist_audio_keybind = 'Ctrl+Shift+e Meta+Shift+e',
}

options.read_options(o, "web-download")

if os.getenv('windir') ~= nil then
    o.device = 'windows'
elseif os.execute '[ $(uname) = "Darwin" ]' == 0 then
    o.device = 'mac'
else
    o.device = 'linux'
end

-- Need to replace $BASENAME, $DIRNAME, and $COUNT
local pre_script
if o.device == 'windows' then
    pre_script = string.char(0xEF, 0xBB, 0xBF)..[[
@ECHO OFF

SET PATH=%PATH%;%CD%
SET BASENAME=$BASENAME

CD "$DIRNAME"
IF %ERRORLEVEL% == 0 GOTO S1
ECHO Failed to go to "$DIRNAME". Press any key to quit.
PAUSE >NUL
EXIT

:S1

IF "%BASENAME%"=="" GOTO S2

IF EXIST "$BASENAME" (
    ECHO "$DIRNAME\$BASENAME" already exists. Press any key to quit.
    PAUSE >NUL
    EXIT
)

MKDIR "$BASENAME"
IF NOT EXIST "$BASENAME" (
    ECHO Failed to create "$DIRNAME\$BASENAME". Press any key to quit.
    PAUSE >NUL
    EXIT
)

CD "$BASENAME"

:S2
ECHO Press any key to download $COUNT file(s) to "$DIRNAME\$BASENAME".
PAUSE >NUL
]]
else
    pre_script = [[
cd "$DIRNAME"
if [ $? -ne 0 ]; then
    read -p 'Failed to go to "$DIRNAME". Press any key to quit.'
    exit 1
fi

if [ ! "$BASENAME" = "" ]; then
    if [ -d "$BASENAME" ] || [ -f "$BASENAME" ]; then
        read -p '"$DIRNAME/$BASENAME" already exists. Press any key to quit.'
        exit
    fi
    
    mkdir "$BASENAME"
    if [ ! -d "$BASENAME" ]; then
        read -p 'Failed to create "$DIRNAME/$BASENAME". Press any key to quit.'
        exit
    fi
    
    cd "$BASENAME"
fi
read -p 'Press any key to download $COUNT file(s) to "$DIRNAME/$BASENAME".'
]]
end

local post_script
if o.device == 'windows' then
    post_script = [[
IF NOT "%BASENAME%"=="" CD ..
ECHO Download completed. Press any key to quit.

PAUSE >NUL & DEL %0 & EXIT
]]
else
    post_script = 'cd .. 2> /dev/null; echo "Download completed."; rm -- "$0"'
end

if o.download_dir == nil or o.download_dir == "" then
    o.download_dir = mp.command_native({"expand-path", "~~/"})..
                     (o.device == 'windows' and "\\downloads" or "/downloads")
else
    local home_dir = os.getenv("HOME") or os.getenv("USERPROFILE")
    o.download_dir = o.download_dir:gsub('%$HOME', home_dir)
    o.download_dir = mp.command_native({"expand-path", o.download_dir})
    if o.device == 'windows' then
        o.download_dir =  o.download_dir:gsub('/', '\\')
    end
end

function osd_error(text)
    msg.error(text)
    mp.osd_message(text)
end

function get_basename()
    local date = os.date("*t")
    return ("%02d%02d%02d-%02d%02d%02d"):format(
        date.year-2000, date.month, date.day, date.hour, date.min, date.sec
        )
end

function bind_keys(keys, name, func, opts)
    if not keys or keys == '' then
        mp.add_forced_key_binding(nil, name, func, opts)
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

function is_url(path)
    return path ~= nil and string.find(path, '://') ~= nil
end

function get_download_script_content(current, audio)
    local playlist = mp.get_property_native('playlist')
    if #playlist == 0 then return nil end
    local command = audio and o.download_audio_command or o.download_command

    local script = ''
    local j = current == true and mp.get_property_number('playlist-pos', 0) or 0
    local k = current == true and j or (#playlist-1)
    local count = 0
    for i=j+1, k+1 do
        local path = playlist[i].filename
        if is_url(path) then
            script = script..command..' "'..path..'"\n'
            count = count+1
        end
    end

    -- Need to replace $BASENAME, $DIRNAME, and $COUNT
    if count ~= 0 then
        local basename = o.download_to_time_dir and get_basename() or ''
        local count_and_type = 
            audio and tostring(count)..' audio' or tostring(count)
        local my_pre_script = pre_script
            :gsub('$BASENAME', basename)
            :gsub('$DIRNAME', o.download_dir)
            :gsub('$COUNT', count_and_type)
        return my_pre_script..script..post_script
    else
        return nil
    end
end

function make_download_script(content)
    local path
    if o.device ~= 'windows' then
        path = o.download_dir..(os.tmpname():gsub('.*/', '/'))..'.sh'
    else
        path = o.download_dir..os.tmpname()
    end

    local file, err = io.open(path, "w")
    if not file then
        return nil
    end

    file:write(content)
    file:close()

    if o.device == 'windows' then
        local new_path = path..'.bat'
        local cmd = "$PSDefaultParameterValues['Out-File:Encoding'] = 'oem';"
            .."Get-Content \""..path.."\" > \""..new_path.."\""
        local args = {
            'powershell', '-NoProfile', '-Command', cmd
        }
        local res = utils.subprocess({args=args, cancellable=false})
        os.remove(path)
        return new_path
    else
        return path
    end
end

function get_my_script_command(path)
    if o.device == 'windows' then
        return o.windows_download:gsub('$download_script', path)
    elseif o.device == 'mac' then
        return o.mac_download:gsub('$download_script', path)
    else
        return o.linux_download:gsub('$download_script', path)
    end
end

function create_dir(dir)
    if utils.readdir(dir) == nil then
        local args
        if o.device == 'windows' then
            args = {
                'powershell', '-NoProfile', '-Command', 'mkdir', dir
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

local is_first = true

function download(current, audio)
    local content = get_download_script_content(current, audio)

    if not content then
        if current then
            mp.osd_message("Current track is not from internet.")
        else
            mp.osd_message("No URLs in the playlist.")
        end
        return
    end

    if is_first then
        is_first = false
        if create_dir(o.download_dir) == false then
            osd_error(
                'Failed to create download directory "'..o.download_dir..'"'
                )
            return
        end
    end

    local path = make_download_script(content)
    if not path then
        mp.osd_message(
            'Failed to create download script in "'..o.download_dir..'".'
            )
        return
    end

    local command = get_my_script_command(path)

    if command == nil or command == '' then
        os.remove(path)
        osd_error(
            'Failed to read download command from "'
                ..mp.command_native({"expand-path", "~~/"})
                ..'/script-opts/web-download.conf".',
            5
            )
    else
        local ret = os.execute(command)
        if not ret then
            msg.error('failed: '..command)
        else
            msg.info(command)
        end
    end
end

bind_keys(o.download_current_track_keybind, 'download-current-track', function()
    download(true, false)
end)
bind_keys(o.download_playlist_keybind, 'download-playlist', function()
    download(false, false)
end)
bind_keys(
    o.download_current_track_audio_keybind, 
    'download-current-track-audio',
    function() download(true, true) end
    )
bind_keys(
    o.download_playlist_audio_keybind, 
    'download-playlist-audio', 
    function() download(false, true) end
    )
