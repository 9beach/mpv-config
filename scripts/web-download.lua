--[[
https://github.com/9beach/mpv-config/blob/main/scripts/web-download.lua

With this script, you can download media files in playlist from web sites
including YouTube, Twitter, Twitch.tv, Naver, Kakao...

You can edit key bindings below in `script-opts/web-download.conf`:

- Downloads currently playing media. (`Ctrl+d, Meta+d`)
- Downloads all media of playlist. (`Ctrl+D, Meta+D`)

To download media files, you need to install
[yt-dlp](https://github.com/yt-dlp/yt-dlp/releases) in your system.
For _Microsoft Windows_ users, just download `yt-dlp.exe` and copy it to
`C:\Windows` or `mpv.exe` directory. For _OSX_ users, run `brew install yt-dlp`.
]]

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local o = {
    download_dir = '~~desktop/',
    download_command = 'yt-dlp --write-sub',
    linux_download = 'gnome-terminal -e "bash \'$download_script\'"',
    windows_download = 'start cmd /c "$download_script"',
    mac_download = 'osascript -e \'tell application "Terminal" to activate\' -e "tell application \"Terminal\" to do script \"bash \'$download_script\'\""',
    -- Keybind for downloading currently playing media.
    download_current_track_keybind = 'Ctrl+d Meta+d',
    -- Keybind for downloading all media of playlist.
    download_playlist_keybind = 'Ctrl+Shift+d Meta+Shift+d',
}

options.read_options(o, "web-download")

if os.getenv('windir') ~= nil then
    o.device = 'windows'
elseif os.execute '[ $(uname) = "Darwin" ]' == 0 then
    o.device = 'mac'
else
    o.device = 'linux'
end

-- Need to replace $DIRNAME, $DOWNLOAD_DIR, and $FILE_COUNT
local pre_script
if o.device == 'windows' then
    pre_script = string.char(0xEF, 0xBB, 0xBF)..[[
@ECHO OFF

SET PATH=%PATH%;%CD%

CD "$DOWNLOAD_DIR"
IF EXIST "$DIRNAME" (
    ECHO "$DOWNLOAD_DIR\$DIRNAME" already exists. Press any key to quit.
    PAUSE >NUL
    EXIT
)

MKDIR "$DIRNAME"
IF NOT EXIST "$DIRNAME" (
    ECHO Failed to create "$DOWNLOAD_DIR\$DIRNAME". Press any key to quit.
    PAUSE >NUL
    EXIT
)

CD "$DIRNAME"

ECHO Press any key to download $FILE_COUNT file(s) in "$DOWNLOAD_DIR\$DIRNAME".
PAUSE >NUL
]]
else
    pre_script = [[
cd "$DOWNLOAD_DIR"
if [ -d "$DIRNAME" ] || [ -f "$DIRNAME" ]; then
    read -p '"$DOWNLOAD_DIR/$DIRNAME" already exists. Press any key to quit.'
    exit
fi

mkdir "$DIRNAME"
if [ ! -d "$DIRNAME" ]; then
    read -p 'Failed to create "$DOWNLOAD_DIR/$DIRNAME". Press any key to quit.'
    exit
fi

cd "$DIRNAME"
read -p 'Press any key to download $FILE_COUNT file(s) in "$DOWNLOAD_DIR/$DIRNAME".'
]]
end

local post_script
if o.device == 'windows' then
    post_script = [[
CD ..
ECHO Download completed. Press any key to quit.
PAUSE >NUL & DEL %0 & EXIT
]]
else
    post_script = [[
cd ..
echo "Download completed. Press CTRL+d to quit terminal."
rm -- "$0"
]]
end

if o.download_dir == nil or o.download_dir == "" then
    o.download_dir = mp.command_native({"expand-path", "~~/"})..
                     (o.device == 'windows' and "\\downloads" or "/downloads")
else
    o.download_dir = mp.command_native({"expand-path", o.download_dir})
end

function get_dirname()
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

function get_download_script_content(current)
    local playlist = mp.get_property_native('playlist')
    if #playlist == 0 then return nil end

    local script = ''
    local j = current == true and mp.get_property_number('playlist-pos', 0) or 0
    local k = current == true and j or (#playlist-1)
    local count = 0
    for i=j+1, k+1 do
        local path = playlist[i].filename
        if is_url(path) then
            script = script..o.download_command..' "'..path..'"\n'
            count = count+1
        end
    end

    -- Need to replace $DIRNAME, $DOWNLOAD_DIR, and $FILE_COUNT
    if count ~= 0 then
        local dirname = get_dirname()
        local my_pre_script = pre_script
            :gsub('$DIRNAME', dirname)
            :gsub('$DOWNLOAD_DIR', o.download_dir)
            :gsub('$FILE_COUNT', tostring(count))
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

function download(current)
    local content = get_download_script_content(current)

    if not content then
        if current then
            mp.osd_message("Current track is not from internet.")
        else
            mp.osd_message("No URLs in the playlist.")
        end
        return
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
        mp.osd_message(
            'Failed to get download command in "'
            ..mp.command_native({"expand-path", "~~/"})
            ..'/script-opts/web-download.conf".',
            5
            )
    else
        os.execute(command)
    end
end

bind_keys(o.download_current_track_keybind, 'download-current-track', function()
    download(true)
end)
bind_keys(o.download_playlist_keybind, 'download-playlist', function()
    download(false)
end)
