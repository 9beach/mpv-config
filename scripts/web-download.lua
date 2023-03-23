--[[
https://github.com/9beach/mpv-config/blob/main/scripts/web-download.lua

With this script, you can download media files of **mpv** playlist from web
sites including YouTube, Twitter, Twitch.tv, Naver, Kakao...

You can edit key bindings below in `script-opts/web-download.conf`:

- Downloads currently playing media. (`Ctrl+d, Meta+d`)
- Downloads all media of **mpv** playlist. (`Ctrl+D, Meta+D`)
- Downloads currently playing media as a audio file. (`Ctrl+e, Meta+e`)
- Downloads all media of **mpv** playlist as audio files. (`Ctrl+E, Meta+E`)
- Downloads currently playing media with alternative option. (`Ctrl+y, Meta+y`)
- Downloads all media of **mpv** playlist with alternative option.
  (`Ctrl+Y, Meta+Y`)

To download media files, you need to install
[yt-dlp](https://github.com/yt-dlp/yt-dlp/releases) in your system.
For _Microsoft Windows_ users, just download `yt-dlp.exe` and copy it to
`C:\Windows` or `mpv.exe` directory. For _OSX_ users, run `brew install yt-dlp`.

To download the highest resolution videos, and preserve chapter markers,
you need to install [ffmpeg](https://ffmpeg.org).
]]

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local o = {
    -- `~~desktop/` is `$HOME/Desktop`, `~~/' is mpv configuration directory.
    -- Supports `$HOME` also for Microsoft Windows.
    download_dir = '$HOME/Downloads',
    -- `yt-dlp` options for downloading video.
    download_command = 'yt-dlp --no-mtime --write-sub -o "%(title)s.%(ext)s"',
    -- If `ffmpeg` is installed, adds the options below to download commands. 
    -- `--embed-chapters` for chapter markers.
    ffmpeg_options = '--embed-chapters',
    -- `yt-dlp` options for downloading audio.
    -- `ba` for 'best audio'.
    download_audio_command = 'yt-dlp -f ba -S ext:m4a --no-mtime -o "%(title)s.%(ext)s"',
    ffmpeg_audio_options = '--embed-chapters',
    -- `yt-dlp` options for alternative downloading.
    download_alternative_command = 'yt-dlp -S ext:mp4 --no-mtime --write-sub -o "%(title)s.%(ext)s"',
    ffmpeg_alternative_options = '--embed-chapters',
    linux_download = 'gnome-terminal -e "bash \'$SCRIPT\'"',
    windows_download = 'start cmd /c "$SCRIPT"',
    mac_download = 'osascript -e \'tell application "Terminal"\' -e \'if not application "Terminal" is running then launch\' -e activate -e "do script \\\"bash \'$SCRIPT\'\\\"" -e end',
    -- Keybind for downloading currently playing media.
    download_current_track_keybind = 'Ctrl+d Meta+d',
    -- Keybind for downloading all media of playlist.
    download_playlist_keybind = 'Ctrl+Shift+d Meta+Shift+d',
    -- Keybind for downloading currently playing media as a audio file.
    download_current_track_audio_keybind = 'Ctrl+e Meta+e',
    -- Keybind for downloading all media of playlist as audio files.
    download_playlist_audio_keybind = 'Ctrl+Shift+e Meta+Shift+e',
    -- Keybind for alternative downloading currently playing media.
    download_current_track_alternative_keybind = 'Ctrl+y Meta+e',
    -- Keybind for alternative downloading all media of playlist.
    download_playlist_alternative_keybind = 'Ctrl+Shift+y Meta+Shift+e',
}

if os.getenv('windir') ~= nil then
    o.platform = 'windows'
elseif os.execute '[ $(uname) = "Darwin" ]' == 0 then
    o.platform = 'darwin'
else
    o.platform = 'linux'
end

options.read_options(o, "web-download")

-- To be replaced __DLCMD, __FFMPEG_OPTS, __DIRNAME, and __COUNT.
local pre_script
if o.platform == 'windows' then
    pre_script = string.char(0xEF, 0xBB, 0xBF)..[[
@ECHO OFF

SET PATH=%PATH%;%CD%
SET DLCMD=__DLCMD

WHERE ffmpeg >NUL 2>NUL
IF %ERRORLEVEL% == 0 SET FFMPEG_OPTS=__FFMPEG_OPTS

ECHO Download command: %DLCMD% %FFMPEG_OPTS%

CD "__DIRNAME"

IF %ERRORLEVEL% == 0 GOTO DOWNLOAD_DIR
ECHO Failed to go to "__DIRNAME". Press ENTER to quit.

PAUSE >NUL & DEL %0 & EXIT 1

:DOWNLOAD_DIR

ECHO Press ENTER to download __COUNT file(s) to "__DIRNAME".
PAUSE >NUL

]]
else
    pre_script = [[
type ffmpeg > /dev/null 2>&1
FFMPEG_INST=$?
if [ $FFMPEG_INST -eq 0 ]; then
cat <<EOF
Download command: __DLCMD __FFMPEG_OPTS
EOF
else
cat <<EOF
Download command: __DLCMD
EOF
fi

cd "__DIRNAME"

if [ $? -ne 0 ]; then
    read -p 'Failed to go to "__DIRNAME". Press ENTER to quit.'
    exit 1
fi

read -p 'Press ENTER to download __COUNT file(s) to "__DIRNAME".'

]]
end

local post_script
if o.platform == 'windows' then
    post_script = [[

IF %ERRORLEVEL% == 0 (ECHO Successfully completed! Press ENTER to quit.) ELSE (ECHO Something wrong but completed. Press ENTER to quit.)

PAUSE >NUL & DEL %0 & EXIT
]]
else
    post_script = [[

if [ $? -eq 0 ]; then
    echo Successfully completed! Bye.
else
    echo Something wrong but completed. Bye.
fi

rm -- "$0"
]]
end

if o.download_dir == nil or o.download_dir == "" then
    o.download_dir = mp.command_native({"expand-path", "~~/"})..
                     (o.platform == 'windows' and "\\downloads" or "/downloads")
else
    local home_dir = os.getenv("HOME") or os.getenv("USERPROFILE")
    o.download_dir = o.download_dir:gsub('%$HOME', home_dir)
    o.download_dir = mp.command_native({"expand-path", o.download_dir})
    if o.platform == 'windows' then
        o.download_dir =  o.download_dir:gsub('/', '\\')
    end
end

function osd_error(text)
    msg.error(text)
    mp.osd_message(text)
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

local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'

string.quote = function(str)
    return str:gsub(quotepattern, "%%%1")
end

function get_download_script_content(current, dl_mode)
    local playlist = mp.get_property_native('playlist')
    if #playlist == 0 then return nil end

    local script = ''

    local j = current == true and mp.get_property_number('playlist-pos', 0) or 0
    local k = current == true and j or (#playlist-1)
    local count = 0
    for i=j+1, k+1 do
        local path = playlist[i].filename
        if is_url(path) then
            if o.platform ~= 'windows' then
                script = script..
                         'if [ $FFMPEG_INST -eq 0 ]; then\n'..
                         '    __DLCMD __FFMPEG_OPTS "'..path..'"\n'..
                         'else\n'..
                         '    __DLCMD "'..path..'"\n'..
                         'fi\n'
            else
                script = script..'%DLCMD% %FFMPEG_OPTS% "'..path..'"\n'
            end
            count = count+1
        end
    end

    if count == 0 then return nil end

    -- Replaces __DLCMD, __FFMPEG_OPTS, __DIRNAME, and __COUNT.
    local dlcmd
    if (dl_mode == 'video') then
        dlcmd = o.download_command
    elseif (dl_mode == 'audio') then
        dlcmd = o.download_audio_command
    else
        dlcmd = o.download_alternative_command
    end
    if o.platform == 'windows' then
        -- `%` is special character in `.bat`
        dlcmd = dlcmd:gsub('%%', '%%%%')
    end

    local count_and_type = 
        'audio' == dl_mode and tostring(count)..' audio' or tostring(count)

    local ffmpeg_options
    if (dl_mode == 'video') then
        ffmpeg_options = o.ffmpeg_options
    elseif (dl_mode == 'audio') then
        ffmpeg_options = o.ffmpeg_audio_options
    else
        ffmpeg_options = o.ffmpeg_alternative_options
    end
    if o.platform == 'windows' then
        -- `%` is special character in `.bat`
        ffmpeg_options = ffmpeg_options:gsub('%%', '%%%%')
    end

    -- No plain string replacement functioin, poor Lua!
    local qdlcmd = string.quote(dlcmd)
    local qffmpeg_options = string.quote(ffmpeg_options)
    local qdownload_dir = string.quote(o.download_dir)
    local qcount_and_type = string.quote(count_and_type)
    return (pre_script..script..post_script)
        :gsub('__DLCMD', qdlcmd)
        :gsub('__FFMPEG_OPTS', qffmpeg_options)
        :gsub('__DIRNAME', qdownload_dir)
        :gsub('__COUNT', qcount_and_type)
end

function make_download_script(content)
    local path
    if o.platform ~= 'windows' then
        path = o.download_dir..(os.tmpname():gsub('.*/', '/wdl-'))..'.sh'
    else
        path = o.download_dir..(os.tmpname():gsub('.*\\', '\\wdl-'))
    end

    local file, err = io.open(path, "w")
    if not file then
        return nil
    end

    file:write(content)
    file:close()

    if o.platform == 'windows' then
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
    if o.platform == 'windows' then
        return o.windows_download:gsub('$SCRIPT', path)
    elseif o.platform == 'darwin' then
        return o.mac_download:gsub('$SCRIPT', path)
    else
        return o.linux_download:gsub('$SCRIPT', path)
    end
end

function create_dir(dir)
    if utils.readdir(dir) == nil then
        local args
        if o.platform == 'windows' then
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

function download(current, dl_mode)
    local content = get_download_script_content(current, dl_mode)

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
        if not ret then msg.error('failed: '..command) end
    end
end

bind_keys(o.download_current_track_keybind, 'download-current-track', function()
    download(true, 'video')
end)
bind_keys(o.download_playlist_keybind, 'download-playlist', function()
    download(false, 'video')
end)
bind_keys(
    o.download_current_track_audio_keybind, 
    'download-current-track-audio',
    function() download(true, 'audio') end
    )
bind_keys(
    o.download_playlist_audio_keybind, 
    'download-playlist-audio', 
    function() download(false, 'audio') end
    )
bind_keys(
    o.download_current_track_alternative_keybind, 
    'download-current-track-alternative',
    function() download(true, 'alternative') end
    )
bind_keys(
    o.download_playlist_alternative_keybind, 
    'download-playlist-alternative', 
    function() download(false, 'alternative') end
    )
