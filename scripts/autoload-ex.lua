--[[
https://github.com/9beach/mpv-config/blob/main/scripts/autoload-ex.lua

This script adds several features to well-known `autoload.lua`. Sets `disabled=yes` as
default value, and adds script messages below:

- script-message autoload-ex shuffle
- script-message autoload-ex shuffle startover
- script-message autoload-ex sort name-asc
- script-message autoload-ex sort name-desc
- script-message autoload-ex sort name-asc startover
- script-message autoload-ex sort name-desc startover
- script-message autoload-ex sort date-asc
- script-message autoload-ex sort date-desc
- script-message autoload-ex sort date-asc startover
- script-message autoload-ex sort date-desc startover
- script-message autoload-ex sort size-asc
- script-message autoload-ex sort size-desc
- script-message autoload-ex sort size-asc startover
- script-message autoload-ex sort size-desc startover

You can edit key bindings in `input.conf`.

Many parts in my code are from
<https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua>.
--]]

MAXENTRIES = 5000

local msg = require 'mp.msg'
local options = require 'mp.options'
local utils = require 'mp.utils'

o = {
    disabled = true,
    images = true,
    videos = true,
    audio = true,
    ignore_hidden = true,
    sort_command_on_autoload = 'name-asc',
}

options.read_options(o, "autoload-ex")

function Set (t)
    local set = {}
    for _, v in pairs(t) do set[v] = true end
    return set
end

function SetUnion (a,b)
    local res = {}
    for k in pairs(a) do res[k] = true end
    for k in pairs(b) do res[k] = true end
    return res
end

EXTENSIONS_VIDEO = Set {
    '3g2', '3gp', 'avi', 'flv', 'm2ts', 'm4v', 'mj2', 'mkv', 'mov',
    'mp4', 'mpeg', 'mpg', 'ogv', 'rmvb', 'webm', 'wmv', 'y4m'
}

EXTENSIONS_AUDIO = Set {
    'aiff', 'ape', 'au', 'flac', 'm4a', 'mka', 'mp3', 'oga', 'ogg',
    'ogm', 'opus', 'wav', 'wma'
}

EXTENSIONS_IMAGES = Set {
    'avif', 'bmp', 'gif', 'j2k', 'jp2', 'jpeg', 'jpg', 'jxl', 'png',
    'svg', 'tga', 'tif', 'tiff', 'webp'
}

EXTENSIONS = Set {}
if o.videos then EXTENSIONS = SetUnion(EXTENSIONS, EXTENSIONS_VIDEO) end
if o.audio then EXTENSIONS = SetUnion(EXTENSIONS, EXTENSIONS_AUDIO) end
if o.images then EXTENSIONS = SetUnion(EXTENSIONS, EXTENSIONS_IMAGES) end

function get_extension(path)
    match = string.match(path, "%.([^%.]+)$" )
    if match == nil then
        return "nomatch"
    else
        return match
    end
end

table.filter = function(t, iter)
    for i = #t, 1, -1 do
        if not iter(t[i]) then
            table.remove(t, i)
        end
    end
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

function get_file_info(path)
    local file_info = utils.file_info(path)
    if not file_info then
        msg.warn('failed to read file info for: '..path)
        return {}
    end

    return file_info
end

function read_dir_by(dir, command, sort_id)
    -- Reads files in the dir
    local files = utils.readdir(dir, "files")
    if files == nil then
        msg.verbose("no other files in directory")
        return {}
    end

    table.filter(files, function (v, k)
        -- The current file could be a hidden file, ignoring it doesn't load other
        -- files from the current directory.
        if (o.ignore_hidden and not (v == filename) and string.match(v, "^%.")) then
            return false
        end
        local ext = get_extension(v)
        if ext == nil then
            return false
        end
        return EXTENSIONS[string.lower(ext)]
    end)

    if command == 'shuffle' then
        for i = #files, 2, -1 do
            local j = math.random(i)
            files[i], files[j] = files[j], files[i]
        end
        return files
    end

    -- Shuffled gone, now sorts by sort_id.
    local index = 1
    for mode, sort_data in pairs(sort_modes) do
        if sort_data.id == sort_id then
            index = mode
        end
    end

    local need_file_info = index ~= 1 and index ~= 2

    local infos = {}
    local sorted = {}

    for i=1, #files do
        sorted[i] = i
        infos[i] = {["filename"] = files[i]}
        if need_file_info then
            infos[i].file_info = get_file_info(dir..files[i])
        end
    end

    table.sort(sorted, function(a, b)
        return sort_modes[index].compar(a, b, infos)
    end)

    for i=1, #files do
        sorted[i] = files[sorted[i]]
    end

    return sorted
end

function split_string(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function autoload_ex(manually_called, command, sort_id, startover)
    local path = mp.get_property("path", "")
    local dir, filename = utils.split_path(path)

    msg.trace(("dir: %s, filename: %s"):format(dir, filename))
    if #dir == 0 then
        msg.verbose("Stopping: not a local path")
        return
    end

    local playlist = mp.get_property_native('playlist')
    local count = #playlist

    -- Checks if automatically called on `start-file` but already has many.
    if not manually_called and count > 1 then
        msg.verbose("Stopping: manually made playlist")
        return
    end

    if manually_called == true then
        mp.osd_message('Loading all the files from the folder.')
    end

    local sorted = read_dir_by(dir, command, sort_id)

    if dir == "." then
        dir = ""
    end

    -- Finds the current pl entry  in the sorted dir list.
    local current
    for i = 1, #sorted do
        if sorted[i] == filename then
            current = i
            break
        end
    end
    if current == nil then
        msg.error("Can't find current file in loaded files: "..filename)
    end

    -- Moves current track to 0
    local pos = mp.get_property_number('playlist-pos', 0)
    mp.commandv("playlist-move", pos, 0)

    -- Removes all the other tracks
    if count > 1 then
        for i = 2, count do
            mp.command("playlist-remove 1")
        end
    end

    local max_count = #sorted > MAXENTRIES and MAXENTRIES or #sorted
    for i=1, max_count do
        local file = sorted[i]
        if file ~= filename then
            mp.commandv("loadfile", dir..file, "append")
        end
    end

    if current ~= 1 and (command ~= 'shuffle' or startover == true) then
        local to
        if current ~= nil and current <= max_count then
            to = current
        else
            to = max_count
        end
        msg.info('current pos: '..current)
        mp.commandv("playlist-move", 0, to)
    end

    if startover == true then
        mp.set_property('playlist-pos', 0)                         
    end

    if manually_called == true then
        mp.osd_message(tostring(#sorted)..' files loaded.')
    end
end

local in_process = false

if o.disabled == false then
    local p = split_string(o.sort_command_on_autoload)
    -- Startover automatically? Nonsense.
    mp.register_event("start-file", function ()
        if not in_process then
            in_process = true
            autoload_ex(false, p[1], p[2], false)
            in_process = false
        else
            msg.info('autoload-ex is currently working.')
        end
    end)
end

mp.register_script_message("autoload-ex", function (p1, p2, p3)
    if not in_process then
        if p1 == 'shuffle' then
            p2, p3 = nil, p2
        end
        in_process = true
        autoload_ex(true, p1, p2, p3 == 'startover')
        in_process = false
    else
        mp.osd_message('autoload-ex is currently working.')
    end
end)
