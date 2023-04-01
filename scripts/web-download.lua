--[[
https://github.com/9beach/mpv-config/blob/main/scripts/web-download.lua

You can download media URLs of **mpv** playlist from web sites including 
YouTube, Twitter, Twitch.tv, Naver, Kakao, ... with this script:

- Downloads currently playing media. (`Ctrl+d, Alt+d, Meta+d`)
- Downloads all media of **mpv** playlist. (`Ctrl+D, Alt+D, Meta+D`)
- Downloads currently playing media as a audio file. (`Ctrl+e, Alt+e, Meta+e`)
- Downloads all media of **mpv** playlist as audio files.
  (`Ctrl+E, Alt+E, Meta+E`)
- Downloads currently playing media with alternative option.
  (`Ctrl+y, Alt+y, Meta+y`)
- Downloads all media of **mpv** playlist with alternative option.
  (`Ctrl+Y, Alt+Y, Meta+Y`)

You can edit key bindings above in `script-opts/web-download.conf`. Please 
notice that:

1. To play and download media from URLs with **mpv**, you need to install
   [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases). For _Microsoft 
   Windows_ users, download
   [yt-dlp.exe](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe)
   and copy it to `C:\Windows`.
2. To download the highest resolution media, and preserve chapter markers,
   you need to install [ffmpeg](https://ffmpeg.org).
]]

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local o = {
    -- Converts the `yt_dlp` option, `%(title)s` to `%(title)#U` in macOS.
    -- **Finder.app** fails to open NFC Korean files very often.
    nfd_for_mac_yt_dlp = true,
    -- `yt-dlp` options for downloading video. `~/` for home directory.
    download_command = 'yt-dlp --no-mtime -o "~/Downloads/%(title)s.%(ext)s"',
    -- If `ffmpeg` is installed, adds the options below to download commands.
    -- `--embed-chapters` for chapter markers.
    ffmpeg_options = '--embed-chapters',
    -- `yt-dlp` options for downloading audio.
    -- `ba` for 'best audio'.
    download_audio_command = 'yt-dlp -f ba -S ext:m4a --no-mtime -o "~/Downloads/%(title)s.%(ext)s"',
    ffmpeg_audio_options = '--embed-chapters',
    -- `yt-dlp` options for alternative downloading.
    download_alternative_command = 'yt-dlp -S ext:mp4 --no-mtime -o "~/Downloads/%(title)s.%(ext)s"',
    ffmpeg_alternative_options = '--embed-chapters',
    linux_download = 'gnome-terminal -e "bash \'$SCRIPT\'"',
    windows_download = 'start cmd /c "$SCRIPT"',
    mac_download = 'osascript -e \'tell application "Terminal"\' -e \'if not application "Terminal" is running then launch\' -e activate -e "do script \\\"bash \'$SCRIPT\'\\\"" -e end',
    -- Keybind for downloading currently playing media.
    download_current_track_keybind = 'Ctrl+d Alt+d Meta+d',
    -- Keybind for downloading all media of playlist.
    download_playlist_keybind = 'Ctrl+Shift+d Alt+Shift+d Meta+Shift+d',
    -- Keybind for downloading currently playing media as a audio file.
    download_current_track_audio_keybind = 'Ctrl+e Alt+e Meta+e',
    -- Keybind for downloading all media of playlist as audio files.
    download_playlist_audio_keybind = 'Ctrl+Shift+e Alt+Shift+e Meta+Shift+e',
    -- Keybind for alternative downloading currently playing media.
    download_current_track_alternative_keybind = 'Ctrl+y Alt+y Meta+y',
    -- Keybind for alternative downloading all media of playlist.
    download_playlist_alternative_keybind = 'Ctrl+Shift+y Alt+Shift+y Meta+Shift+y',
}

if os.getenv('windir') ~= nil then
    o.platform = 'windows'
elseif os.execute '[ $(uname) = "Darwin" ]' == 0 then
    o.platform = 'darwin'
else
    o.platform = 'linux'
end

options.read_options(o, "web-download")

-- To be replaced __DLCMD, __URLS_PATH, __FFMPEG_OPTS, and __COUNT.
local script

if o.platform == 'windows' then
    script = string.char(0xEF, 0xBB, 0xBF)..[[
@ECHO OFF

SET PATH=%PATH%;__EXE_DIR
SET DLCMD=__DLCMD
SET URLS_PATH="__URLS_PATH"

WHERE ffmpeg >NUL 2>NUL
IF %ERRORLEVEL% == 0 SET FFMPEG_OPTS=__FFMPEG_OPTS

ECHO Download command: %DLCMD% %FFMPEG_OPTS%

ECHO Press ENTER to download __COUNT file(s).
PAUSE >NUL

%DLCMD% %FFMPEG_OPTS% -a %URLS_PATH%
DEL %URLS_PATH%

IF %ERRORLEVEL% == 0 (ECHO Successfully completed! Press ENTER to quit.) ELSE (ECHO Not successful. Press ENTER to quit.)

PAUSE >NUL & DEL %0 & EXIT
]]
    local exe_dir = mp.command_native({"expand-path", "~~exe_dir/"})
    script = script:gsub('__EXE_DIR', (exe_dir:gsub("%%", "%%%%")))
else
    script = [[
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

read -p 'Press ENTER to download __COUNT file(s).'

if [ $FFMPEG_INST -eq 0 ]; then
    __DLCMD __FFMPEG_OPTS -a "__URLS_PATH"
else
    __DLCMD -a "__URLS_PATH"
fi

LAST_ERROR=$?

if [ "$(uname)" = "Darwin" ]; then
    if [ $LAST_ERROR -eq 0 ]; then
        echo Successfully completed! Bye.
    else
        echo Not successful, but bye.
    fi
else
    if [ $LAST_ERROR -eq 0 ]; then
        read -p 'Successfully completed! Press ENTER to quit.'
    else
        read -p 'Not successful. Press ENTER to quit.'
    fi
fi

rm -- "$0" "__URLS_PATH"
]]
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

function tmppath()
    if o.platform == 'windows' then
        return os.getenv('temp')..(os.tmpname():gsub('.*\\(.*)', '\\webdl-%1o'))
    else
        return os.tmpname()
    end
end

local home_dir = mp.command_native({"expand-path", "~/"})..'/'
local mpv_dir = mp.command_native({"expand-path", "~~/"})..'/'

-- Returns `return_code`, `count`, and `urlspath`.
-- 0: Success.
-- 1: No URLs.
-- 2: Failed to create URLs file.
-- 3: Nothing loaded.
function make_urlsfile(current)
    local playlist = mp.get_property_native('playlist')
    if #playlist == 0 then
        mp.osd_message('Nothing loaded in the playlist.')
        return 3
    end

    local urls = ''

    local j = current == true and mp.get_property_number('playlist-pos', 0) or 0
    local k = current == true and j or (#playlist-1)
    local count = 0

    for i=j+1, k+1 do
        local path = playlist[i].filename
        if is_url(path) then
            urls = urls..path.."\n"
            count = count + 1
        end
    end

    if count == 0 then
        if current then
            mp.osd_message("Current track is not from internet.")
        else
            mp.osd_message("No URLs in the playlist.")
        end
        return 1
    end

    local urlspath = tmppath()
    local file, err = io.open(urlspath, "w")
    if not file then
        mp.osd_message('Failed to create temporary file: '..urlspath)
        return 2
    end
    file:write(urls)
    file:close()

    return 0, count, urlspath
end

-- Replaces `__*` from `script`.
function get_download_script(dlmode, count, urlspath)
    local dlcmd

    if (dlmode == 'video') then
        dlcmd = o.download_command
    elseif (dlmode == 'audio') then
        dlcmd = o.download_audio_command
    else
        dlcmd = o.download_alternative_command
    end

    dlcmd = dlcmd
        :gsub('([:;, ="\'])(~~/)', '%1'..(mpv_dir:gsub("%%", "%%%%")))
        :gsub('([:;, ="\'])(~/)', '%1'..(home_dir:gsub("%%", "%%%%")))

    if o.platform == 'windows' then
        -- `%` is special character in `.bat`
        dlcmd = dlcmd:gsub('%%', '%%%%')
    elseif o.platform == 'darwin' and o.nfd_for_mac_yt_dlp then
        dlcmd = dlcmd:gsub('%%%(title%)s', '%%(title)#U')
    end

    local ffmpeg_options

    if (dlmode == 'video') then
        ffmpeg_options = o.ffmpeg_options
    elseif (dlmode == 'audio') then
        ffmpeg_options = o.ffmpeg_audio_options
    else
        ffmpeg_options = o.ffmpeg_alternative_options
    end

    ffmpeg_options = ffmpeg_options
            :gsub('([:;, ="\'])(~~/)', '%1'..(mpv_dir:gsub("%%", "%%%%")))
            :gsub('([:;, ="\'])(~/)', '%1'..(home_dir:gsub("%%", "%%%%")))

    if o.platform == 'windows' then
        -- `%` is special character in `.bat`
        ffmpeg_options = ffmpeg_options:gsub('%%', '%%%%')
    elseif o.platform == 'darwin' and o.nfd_for_mac_yt_dlp then
        ffmpeg_options = ffmpeg_options:gsub('%%%(title%)s', '%%(title)#U')
    end

    local count_and_type =
        'audio' == dlmode and tostring(count)..' audio' or tostring(count)

    -- No plain string replacement functioin, poor Lua!
    return script
        :gsub('__DLCMD', (dlcmd:gsub("%%", "%%%%")))
        :gsub('__FFMPEG_OPTS', (ffmpeg_options:gsub("%%", "%%%%")))
        :gsub('__COUNT', (count_and_type:gsub("%%", "%%%%")))
        :gsub('__URLS_PATH', (urlspath:gsub("%%", "%%%%")))
end

-- Quotes string for powershell path including "'"
function ps_quote_string(str)
    return "'"..str:gsub('`', '``'):gsub('"', '``"'):gsub('%$', '``$')
                   :gsub('%[', '``['):gsub('%]', '``]'):gsub("'", "''").."'"
end

-- `cmd.exe` can't read UTF-8, so we need to convert it to oem encoding
-- with `powershell.exe`.
function ps_iconv_to_oem(in_utf8_filepath, out_oem_filepath)
    local cmd = "Get-Content "..ps_quote_string(in_utf8_filepath)..
        " | Set-Content -Encoding oem "..ps_quote_string(out_oem_filepath)
    local args = {
        'powershell', '-NoProfile', '-Command', cmd
    }
    return utils.subprocess({args=args, cancellable=false})
end

function make_download_script(dlmode, count, urlspath)
    local content = get_download_script(dlmode, count, urlspath)
    local path = o.platform ~= 'windows' and urlspath..'.sh' or urlspath..'-utf8file'

    local file, err = io.open(path, "w")
    if not file then
        msg.error('Failed to open:', path)
        return nil
    end

    file:write(content)
    file:close()

    if o.platform == 'windows' then
        local new_path = urlspath..'-oem-encoded.bat'
        ps_iconv_to_oem(path, new_path)
        os.remove(path)
        return new_path
    else
        return path
    end
end

function get_start_download_script(path)
    if o.platform == 'windows' then
        return o.windows_download:gsub('$SCRIPT', path)
    elseif o.platform == 'darwin' then
        return o.mac_download:gsub('$SCRIPT', path)
    else
        return o.linux_download:gsub('$SCRIPT', path)
    end
end

function download(current, dlmode)
    local ret, count, urlspath = make_urlsfile(current)
    if ret ~= 0 then return end
    local path = make_download_script(dlmode, count, urlspath)
    if nil == path then
        mp.osd_message('Failed to create download script.')
        return
    end

    local start = get_start_download_script(path)

    if start == '' then
        os.remove(path)
        os.remove(urlspath)
        osd_error(
            "Something's wrong: "..mpv_dir.."/script-opts/web-download.conf"
            )
    else
        local ret = os.execute(start)
        if not ret then
            os.remove(path)
            os.remove(urlspath)
            osd_error(
                "Something's wrong: "..mpv_dir.."/script-opts/web-download.conf"
                )
        end
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
