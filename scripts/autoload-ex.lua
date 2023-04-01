--[[
https://github.com/9beach/mpv-config/blob/main/scripts/autoload-ex.lua

This script provides the functions below:

- Like well-known `autoload`, automatically loads playlist entries by scanning
  the directory a file is located in when starting playback.
- Provides many sorting methods and shuffling when scanning the directory.
- Provides keybinds for the functions of scannig the directory, sorting and
  shuffling the files.
- Remembers the sorting and shuffling states of the directory. So when you
  open a file in the directory next time, `autoload-ex` restores previous
  sorting states of the directory.
- Even though you set `disabled=yes` in `script-opts/autoload-ex.conf` and
  call `autoload-ex` manually by keybinds, `autoload-ex` scans entries of the
  directory automatically next time.
- If you set `disabled=no` and call `autoload-ex remove-others` manually by
  keybinds, `autoload-ex` does not scan entries of the directory next time.

Notice that when manually called, `autoload-ex` does reload and sort not
the current playlist entries, but the files in the directory of the current
track. It means that `autoload-ex` remembers the state of a directory, not
that of a playlist.

This script provides the script messages below:

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
- script-message autoload-ex remove-others

You can edit key bindings in `input.conf`.

```
META+SHIFT+n script-message autoload-ex sort name-asc
META+SHIFT+t script-message autoload-ex sort date-desc
META+SHIFT+s script-message autoload-ex shuffle startover
META+SHIFT+r script-message autoload-ex remove-others
...
```

Many parts in my code are from
<https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua>,
<http://lua-users.org/wiki/SecureHashAlgorithm>, and
<https://www.snpedia.com/extensions/Scribunto/engines/LuaCommon/lualib/bit32.lua>.
--]]

-- Minified code below defines `function sha256(message)`, and is a combination of <http://lua-users.org/wiki/SecureHashAlgorithm> and <https://www.snpedia.com/extensions/Scribunto/engines/LuaCommon/lualib/bit32.lua>.
local sha256; do local b,c,d,e,f;if bit32 then b,c,d,e,f=bit32.band,bit32.rrotate,bit32.bxor,bit32.rshift,bit32.bnot else f=function(g)g=math.floor(tonumber(g))%0x100000000;return(-g-1)%0x100000000 end;local h={[0]={[0]=0,0,0,0},[1]={[0]=0,1,0,1},[2]={[0]=0,0,2,2},[3]={[0]=0,1,2,3}}local i={[0]={[0]=0,1,2,3},[1]={[0]=1,0,3,2},[2]={[0]=2,3,0,1},[3]={[0]=3,2,1,0}}local function j(k,l,m,n,o)for p=1,m do l[p]=math.floor(tonumber(l[p]))%0x100000000 end;local q=1;local r=0;for s=0,31,2 do local t=n;for p=1,m do t=o[t][l[p]%4]l[p]=math.floor(l[p]/4)end;r=r+t*q;q=q*4 end;return r end;b=function(...)return j('band',{...},select('#',...),3,h)end;d=function(...)return j('bxor',{...},select('#',...),0,i)end;e=function(g,u)g=math.floor(tonumber(g))%0x100000000;u=math.floor(tonumber(u))u=math.min(math.max(-32,u),32)return math.floor(g/2^u)%0x100000000 end;c=function(g,u)g=math.floor(tonumber(g))%0x100000000;u=-math.floor(tonumber(u))%32;local g=g*2^u;return g%0x100000000+math.floor(g/0x100000000)end end;local v={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}local function w(n)return string.gsub(n,".",function(t)return string.format("%02X",string.byte(t))end)end;local function x(y,z)local n=""for p=1,z do local A=y%256;n=string.char(A)..n;y=(y-A)/256 end;return n end;local function B(n,p)local z=0;for p=p,p+3 do z=z*256+string.byte(n,p)end;return z end;local function C(D,E)local F=-(E+1+8)%64;E=x(8*E,8)D=D.."\128"..string.rep("\0",F)..E;return D end;local function G(H)H[1]=0x6a09e667;H[2]=0xbb67ae85;H[3]=0x3c6ef372;H[4]=0xa54ff53a;H[5]=0x510e527f;H[6]=0x9b05688c;H[7]=0x1f83d9ab;H[8]=0x5be0cd19;return H end;local function I(D,p,H)local J={}for K=1,16 do J[K]=B(D,p+(K-1)*4)end;for K=17,64 do local L=J[K-15]local M=d(c(L,7),c(L,18),e(L,3))L=J[K-2]local N=d(c(L,17),c(L,19),e(L,10))J[K]=J[K-16]+M+J[K-7]+N end;local O,s,t,P,Q,R,S,T=H[1],H[2],H[3],H[4],H[5],H[6],H[7],H[8]for p=1,64 do local M=d(c(O,2),c(O,13),c(O,22))local U=d(b(O,s),b(O,t),b(s,t))local V=M+U;local N=d(c(Q,6),c(Q,11),c(Q,25))local W=d(b(Q,R),b(f(Q),S))local X=T+N+W+v[p]+J[p]T=S;S=R;R=Q;Q=P+X;P=t;t=s;s=O;O=X+V end;H[1]=b(H[1]+O)H[2]=b(H[2]+s)H[3]=b(H[3]+t)H[4]=b(H[4]+P)H[5]=b(H[5]+Q)H[6]=b(H[6]+R)H[7]=b(H[7]+S)H[8]=b(H[8]+T)end;local function Y(H)return w(x(H[1],4)..x(H[2],4)..x(H[3],4)..x(H[4],4)..x(H[5],4)..x(H[6],4)..x(H[7],4)..x(H[8],4))end;local Z={}sha256=function(D)D=C(D,#D)local H=G(Z)for p=1,#D,64 do I(D,p,H)end;return Y(H)end end

local msg = require 'mp.msg'
local options = require 'mp.options'
local utils = require 'mp.utils'

o = {
    disabled = true,
    loaded_then_autoload = true,
    images = false,
    videos = true,
    audio = true,
    ignore_hidden = true,
    -- shuffle, sort name-asc, sort date-asc, sort size-asc, sort name-desc, ...
    sort_command_on_autoload = 'sort name-asc',
}

if os.getenv('windir') ~= nil then
    o.platform = 'windows'
elseif os.execute '[ $(uname) = "Darwin" ]' == 0 then
    o.platform = 'darwin'
else
    o.platform = 'linux'
end

options.read_options(o, "autoload-ex")

function pipe_read(cmd)
    local f = io.popen(cmd, 'r')
    local s = f:read('*a')
    f:close()
    if s == '' or s == nil then
        msg.error(cmd)
        return nil
    end
    return s
end

function make_set(t)
    local set = {}
    for _, v in pairs(t) do set[v] = true end
    return set
end

function set_union(a,b)
    local res = {}
    for k in pairs(a) do res[k] = true end
    for k in pairs(b) do res[k] = true end
    return res
end

video_extensions = make_set {
    '3g2', '3gp', 'avi', 'flv', 'm2ts', 'm4v', 'mj2', 'mkv', 'mov',
    'mp4', 'mpeg', 'mpg', 'ogv', 'rmvb', 'webm', 'wmv', 'y4m'
}

audio_extensions = make_set {
    'aiff', 'ape', 'au', 'flac', 'm4a', 'mka', 'mp3', 'oga', 'ogg',
    'ogm', 'opus', 'wav', 'wma'
}

images_extensions = make_set {
    'avif', 'bmp', 'gif', 'j2k', 'jp2', 'jpeg', 'jpg', 'jxl', 'png',
    'svg', 'tga', 'tif', 'tiff', 'webp'
}

media_extensions = make_set {}

if o.videos then
    media_extensions = set_union(media_extensions, video_extensions)
end
if o.audio then
    media_extensions = set_union(media_extensions, audio_extensions)
end
if o.images then
    media_extensions = set_union(media_extensions, images_extensions)
end

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
        if not iter(t[i]) then table.remove(t, i) end
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

function sortid2index(sort_id)
    local index = 1
    for mode, sort_data in pairs(sort_modes) do
        if sort_data.id == sort_id then
            index = mode
        end
    end
    return index
end

function readdir_by(dir, command, sort_id)
    -- Reads files in the dir.
    local files = utils.readdir(dir, "files")
    if files == nil then
        msg.verbose("no other files in directory")
        return {}
    end

    table.filter(files, function (v, k)
        -- The current file could be a hidden file, ignoring it doesn't load 
        -- other files from the current directory.
        if (o.ignore_hidden and v ~= filename and string.match(v, "^%.")) then
            return false
        end
        local ext = get_extension(v)
        if ext == nil then
            return false
        end
        return media_extensions[string.lower(ext)]
    end)

    if command == 'shuffle' then
        for i = #files, 2, -1 do
            local j = math.random(i)
            files[i], files[j] = files[j], files[i]
        end
        return files
    end

    -- 'shuffle' returned, now sorts by sort_id.
    local index = sortid2index(sort_id)
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

-- Quotes string for powershell path including "'"
function ps_quote_string(str)
    return "'"..str:gsub('`', '``'):gsub('"', '``"'):gsub('%$', '``$')
                   :gsub('%[', '``['):gsub('%]', '``]'):gsub("'", "''").."'"
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

local watch_later = mp.command_native({"expand-path", "~~/"})..'/watch_later/'
local first_read = true

function read_sorting_states(dir)
    if first_read then
        first_read = false
        create_dir(watch_later)
    end

    local states = {}
    local path = watch_later..sha256(dir)
    local f = io.open(path, "r")

    local command, sort_id
    if f then
        for line in io.lines(path) do
            k, v = line:match("([^=]+)=(.+)")
            if k and k == 'command' then command = v end
            if k and k == 'sort_id' then sort_id = v end
        end
        f:close()
    end
    return command, sort_id
end

function write_sorting_states(dir, command, sort_id)
    local path = watch_later..sha256(dir)
    local f = io.open(path, "w+")
    if f then
        local content = "command="..command.."\n"
        if sort_id then content = content..'sort_id='..sort_id.."\n" end
        f:write(content)
        f:close()
    end
end

function is_local_file(path)
    return path ~= nil and string.find(path, '://') == nil
end

function remove_others_silently(count)
    if count and count == 1 then return end

    -- Moves current track to 0 pos.
    local pos = mp.get_property_number('playlist-pos', 0)
    mp.commandv("playlist-move", pos, 0)

    if count == nil then
        count = mp.get_property_number('playlist-count', 0)
    end

    -- Removes all the other tracks.
    if count > 1 then
        for i = count-1, 1, -1 do mp.command("playlist-remove "..i) end
    end

    return count-1
end

-- commands: sort, shuffle, and remove-others.
function autoload_ex(on_start_file, command, sort_id, startover)
    msg.info('called:', on_start_file, command, sort_id, startover)

    local path = mp.get_property("path", "")
    if not is_local_file(path) then
        if not on_start_file and command == 'remove-others' then
            if remove_others_silently() > 0 then
                mp.osd_message('All the other tracks removed.')
            end
        end
        return
    end

    local dir, filename = utils.split_path(path)

    local ext = get_extension(filename)
    if ext == nil or not media_extensions[string.lower(ext)] then
        msg.info('stopping: no interesting file,', path)
        return
    end

    if #dir == 0 then
        msg.info("stopping: not a local path,", path)
        return
    end

    local playlist = mp.get_property_native('playlist')
    local count = #playlist

    if (count < 2 and 'remove-others' == command) then
        msg.verbose("stopping: remove-others for single entry playlist")
        return
    end

    if on_start_file and count > 1 then
        msg.info("stopping: already scanned, or manually made playlist")
        return
    end

    if not on_start_file then
        mp.osd_message('Scanning dir: '..dir)
    end

    local p_command, p_sort_id = read_sorting_states(dir)

    if o.disabled and on_start_file then
        if p_command ~= 'sort' and p_command ~= 'shuffle' then return end
        msg.info('`disabled=yes`, but previously loaded, so scan dir')
    end

    if not o.disabled and on_start_file then
        if p_command == 'remove-others' then
            msg.info('`remove-others` called previously, so does not scan dir')
            return
        end
    end

    if not on_start_file then
        msg.info('direct command:', command, sort_id, startover)
    elseif p_command ~= nil then
        command, sort_id = p_command, p_sort_id
        msg.info('restored `start-file` command:', p_command, p_sort_id)
    else
        msg.info('`start-file` command:', command, sort_id)
    end

    -- First, removes the other tracks before some scripts modify my playlist.
    remove_others_silently(count)

    if command == 'remove-others' then
        if not on_start_file then
            mp.osd_message('All the other tracks removed.')
            write_sorting_states(dir, command, sort_id)
        end
        return
    end

    -- Actually shuffled_or_sorted.
    local sorted 
    local current

    sorted = readdir_by(dir, command, sort_id)

    if #sorted == 0 then
        msg.error("impossible, no other files in the dir!:", filename)
        return
    end

    local altname

    -- Finds the current track in `sorted` and removes it.
    for i = 1, #sorted do
        if sorted[i] == filename then
            current = i
            table.remove(sorted, current)
            break
        end
    end

    if current == nil and o.platform == 'darwin' then
        -- Converts UTF-8 NFD filenames to UTF-8 NFC.
        -- `readdir` returns real filenames, but **Finder.app** passes
        -- NFD filenames to MPV. We don't know those're of NFD originally.
        altname = pipe_read(
            "perl -E 'use Encode qw/encode decode/; use Unicode::Normalize "..
            "qw/compose/; print encode(\"utf8\", compose(decode(\"utf8\",\""..
            filename.."\")));'"
            )
        if altname ~= nil and altname ~= '' then
            for i = 1, #sorted do
                if sorted[i] == altname then
                    current = i
                    table.remove(sorted, current)
                    break
                end
            end
        end
    end
    if current == nil then
        msg.error("can't find current file in reloaded files:", filename)
        current = 1
    end

    -- A directory with only one track needs to be remembered?
    if not on_start_file and #sorted > 0 then
        write_sorting_states(dir, command, sort_id)
    end

    -- Adds `sorted` to playlist.
    local my_dir = dir == "." and "" or dir
    local tails_count = #sorted > 5000 and 5000 or #sorted

    for i=1, tails_count do
        mp.commandv("loadfile", my_dir..sorted[i], "append")
    end

    -- If shuffle and no startover, current track goes to the first.
    -- It's essential for on_start_file case.
    if (command == 'shuffle' and not startover) then
        current = 1
    else
        current = current <= tails_count and current or tails_count+1
        mp.commandv("playlist-move", 0, current)
    end

    -- The same track does not need to restart.
    if startover == true and current > 1 then
        mp.set_property('playlist-pos', 0)                         
    end

    if not on_start_file then
        if command == 'shuffle' then
            mp.osd_message('Shuffled '..(tails_count+1)..' files.')
        else
            mp.osd_message(
                'Loaded '..(tails_count+1)..' files sorted by '..
                sort_modes[sortid2index(sort_id)].title.."."
                )
        end
    end
end

local in_process = false
local p = split_string(o.sort_command_on_autoload)

mp.register_event("start-file", function ()
    if not in_process then
        in_process = true
        -- Startover automatically? Nonsense.
        autoload_ex(true, p[1], p[2], false)
        in_process = false
    else
        msg.info('autoload-ex is currently working.')
    end
end)

mp.register_script_message("autoload-ex", function (p1, p2, p3)
    if not in_process then
        in_process = true
        if p1 == 'shuffle' then
            p2, p3 = nil, p2
        end
        autoload_ex(false, p1, p2, p3 == 'startover')
        in_process = false
    else
        mp.osd_message('autoload-ex is currently working.')
    end
end)
