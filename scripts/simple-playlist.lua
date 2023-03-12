--[[
https://github.com/9beach/mpv-config/blob/main/scripts/simple-playlist.lua

This script provides script messages below:

* script-message simple-playlist sort date-desc
* script-message simple-playlist sort date-asc
* script-message simple-playlist sort date-desc startover

`simple-playlist sort` also support `size-asc`, `size-desc`, `name-asc`,
`name-desc` with or without `startover`.

* script-message simple-playlist shuffle
* script-message simple-playlist reverse
* script-message simple-playlist playfirst
* script-message simple-playlist playlast
* script-message simple-playlist save
* script-message simple-playlist show-text 5
* script-message simple-playlist show-osc 5
* script-message simple-playlist hide

`5` in `show-text` and `show-osc` is the duration in seconds. To keep the code
simple, the playlist is not refreshed automatically, so another `show-text` or
`show-osc` is needed to refresh the playlist. You can edit key bindings in
`input.conf`.

Many parts in the code are from <https://github.com/jonniek/mpv-playlistmanager>
and <https://github.com/zsugabubus/dotfiles/blob/master/.config/mpv/scripts/playlist-filtersort.lua>.
]]

local options = require 'mp.options'
local utils = require 'mp.utils'
local msg = require 'mp.msg'

local o = {
    -- `~~desktop/` is `$HOME/Desktop`, `~~/' is mpv configuration directory.
    playlist_dir = '~~desktop/',
}

options.read_options(o, "simple-playlist")

if os.getenv('windir') ~= nil then
    o.device = 'windows'
elseif os.execute '[ $(uname) = "Darwin" ]' == 0 then
    o.device = 'mac'
else
    o.device = 'linux'
end

if o.playlist_dir == nil or o.playlist_dir == "" then
    o.playlist_dir = mp.command_native({"expand-path", "~~/"}).."/playlists"
else
    o.playlist_dir = mp.command_native({"expand-path", o.playlist_dir})
end

math.randomseed(os.time())

function alphanum_compar(a, b)
    local function padnum(d)
        local dec, n = string.match(d, "(%.?)0*(.+)")
        return #dec > 0 and ("%.12f"):format(d) or
               ("%s%03d%s"):format(dec, #n, n)
    end
    return tostring(a):lower():gsub("%.?%d+",padnum)..("%3d"):format(#b) <
           tostring(b):lower():gsub("%.?%d+",padnum)..("%3d"):format(#a)
end

local sort_modes = {
    {
        id="name-asc",
        title="name",
        compar=function (a, b, pl)
            return alphanum_compar(pl[a].filename, pl[b].filename)
        end,
    },
    {
        id="name-desc",
        title="name in descending order",
        compar=function (a, b, pl)
            return alphanum_compar(pl[b].filename, pl[a].filename)
        end,
    },
    {
        id="date-asc",
        title="date",
        compar=function (a, b, pl)
            return (pl[a].file_info.mtime or 0) < (pl[b].file_info.mtime or 0)
        end,
    },
    {
        id="date-desc",
        title="date in descending order",
        compar=function (a, b, pl)
            return (pl[b].file_info.mtime or 0) < (pl[a].file_info.mtime or 0)
        end,
    },
    {
        id="size-asc",
        title="size",
        compar=function (a, b, pl)
            return (pl[a].file_info.size or 0) < (pl[b].file_info.size or 0)
        end,
    },
    {
        id="size-desc",
        title="size in descending order",
        compar=function (a, b, pl)
            return (pl[b].file_info.size or 0) < (pl[a].file_info.size or 0)
        end,
    },
}

function osd_error(text)
    msg.error(text)
    mp.osd_message(text)
end

function osd_info(text)
    msg.info(text)
    mp.osd_message(text)
end

function is_local_file(path)
    return path ~= nil and string.find(path, '://') == nil
end

function hide_playlist()
    mp.command("script-message osc-playlist 0")
    mp.command("show-text ${playlist} 0")
end

function show_playlist(osc, duration)
    if duration ~= nil then
        if osc then
            duration = ' '..duration -- seconds
        else
            duration = ' '..duration..'000' -- milliseconds
        end
    else
        duration = ''
    end

    if osc then
        mp.command("show-text ' ' 0")
        mp.command("script-message osc-playlist"..duration)
    else
        mp.command("script-message osc-playlist 0")
        mp.command("show-text ${playlist}"..duration)
    end
end

function get_file_info(playlist, item)
    local path = playlist[item].filename
    if not is_local_file(path) then return {} end

    local file_info = utils.file_info(path)
    if not file_info then
        msg.warn('failed to read file info for: '..path)
        return {}
    end

    return file_info
end

-- Always does not start over.
function reverse_playlist()
    local length = mp.get_property_number('playlist-count', 0)
    if length < 2 then return end
    for outer=1, length-1, 1 do
        mp.commandv('playlist-move', outer, 0)
    end

    mp.osd_message("Playlist reversed")
end

-- Always starts over.
function shuffle_playlist()
    local length = mp.get_property_number('playlist-count', 0)
    if length < 2 then return end

    local pos = mp.get_property_number('playlist-pos', 0)

    mp.command("playlist-shuffle")
    mp.commandv("playlist-move", pos, math.random(0, length-1))

    mp.osd_message("Playlist shuffled")
    mp.set_property('playlist-pos', 0)
end

function sort_playlist_by(sort_id, startover)
    local index = 1
    for mode, sort_data in pairs(sort_modes) do
        if sort_data.id == sort_id then
            index = mode
        end
    end

    local need_file_info = index ~= 1 and index ~= 2

    local playlist = mp.get_property_native('playlist')
    if #playlist < 2 then return end

    mp.osd_message("Sorting playlist by "..sort_modes[index].title.."...", 30)

    local order = {}
    for i=1, #playlist do
        order[i] = i
        if need_file_info then
            playlist[i].file_info = get_file_info(playlist, i)
        end
    end

    table.sort(order, function(a, b)
        return sort_modes[index].compar(a, b, playlist)
    end)

    for i=1, #playlist do
        playlist[order[i]].new_pos = i
    end

    for i=1, #playlist do
        while true do
            local j = playlist[i].new_pos
            if i == j then
                break
            end
            mp.commandv('playlist-move', (i)     - 1, (j + 1) - 1)
            mp.commandv('playlist-move', (j - 1) - 1, (i)     - 1)
            playlist[j], playlist[i] = playlist[i], playlist[j]
        end
    end

    mp.osd_message("Playlist sorted")

    if startover == 'startover' then
        mp.set_property('playlist-pos', 0)
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
    end
    return true
end

function save_playlist()
    local playlist = mp.get_property_native('playlist')
    if #playlist == 0 then return end

    if create_dir(o.playlist_dir) == false then
        osd_error('Failed to create playlist directory "'..o.playlist_dir..'"')
        return
    end

    local date = os.date("*t")
    local name = ("mpv-%04d-%02d%02d%02d-%02d%02d%02d.m3u"):format(
        #playlist, date.year-2000, date.month, date.day, 
        date.hour, date.min, date.sec
        )

    local path = utils.join_path(o.playlist_dir, name)
    local file, err = io.open(path, "w")
    if not file then
        osd_error('Error in creating playlist file "'..path..'"')
        return
    end

    file:write("#EXTM3U\n")
    local pwd = mp.get_property("working-directory")

    local is_windows = o.device == 'windows'
    for i=1, #playlist do
        msg.info(playlist[i].filename)
        local item_path = playlist[i].filename
        if is_local_file(item_path) then
            item_path = utils.join_path(pwd, item_path)
            if is_windows then
                item_path = string.gsub(item_path, '/', '\\')
            end
        end
        file:write(item_path, "\n")
    end

    file:close()

    osd_info('Playlist written to "'..path..'"')
end

mp.register_script_message("simple-playlist", function (param1, param2, param3)
    if param1 == 'sort' then
        sort_playlist_by(param2, param3)
    elseif param1 == 'shuffle' then
        shuffle_playlist()
    elseif param1 == 'reverse' then
        reverse_playlist()
    elseif param1 == 'show-text' then
        show_playlist(false, param2)
    elseif param1 == 'show-osc' then
        show_playlist(true, param2)
    elseif param1 == 'hide' then
        hide_playlist()
    elseif param1 == 'save' then
        save_playlist()
    elseif param1 == 'playfirst' then
        local length = mp.get_property_number('playlist-count', 0)
        if length < 2 then
            return
        else
            mp.set_property("playlist-pos", 0)
        end
    elseif param1 == 'playlast' then
        local playlist = mp.get_property_native('playlist')
        if #playlist < 2 then
            return
        else
            mp.set_property("playlist-pos", #playlist - 1)
        end
    end
end)
