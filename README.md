# My mpv settings

This repository contains several [Lua](http://lua.org) scripts and settings
I wrote for open-source media player [mpv](https://mpv.io). Many parts in my
code are from internet obviously.

## Installation

You can install each Lua script below individually by just copying it. Please
notice that the installation script is probably just for me, and also that
subtitle settings of `mpv.conf` and `script-opts/on-file-loaded.conf` are for
Koreans. Anyhow it installs all the scripts and settings of this repository.

First [install mpv](https://mpv.io/installation/) and then download
[`9beach/mpv-config`](https://github.com/9beach/mpv-config/archive/refs/heads/main.zip).
Before install it. Please notice that:

1. To play and download media from URLs with **mpv**, you need to install
   [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases). For 
   _Microsoft Windows_ users, download
   [yt-dlp.exe](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe)
   and copy it to `C:\Windows`.
2. To download the highest resolution media, and preserve chapter markers,
   you need to install [ffmpeg](https://ffmpeg.org).

In Mac or Linux, run the following from the terminal. Then it installs
`9beach/mpv-config` to your **mpv** configuration directory. Your original
**mpv** settings are copied to `~/Downloads` directory if it exists.

```console
cd mpv-config-main
./install.sh
```

If your machine has NVIDIA GPU installed, run `./install.sh nvidia`.

If you prefer `portable_config`, run the following.

```
MPV_CONF_PATH="path-to-my-mpv/portable_config" ./install.sh
```

In _Microsoft Windows_, run the following from the `Command Prompt`, or
double-click `install.bat` in file explorer.

```console
C:\path-to\mpv-config-main> install.bat
```

If your machine has NVIDIA GPU installed, run `install.bat nvidia`.

If you prefer `portable_config`, run the following.

```
C:\path-to\mpv-config-main> SET MPV_CONF_PATH=C:\path-to-my-mpv\portable_config
C:\path-to\mpv-config-main> install.bat
```

Notice that there are no quotation marks in `MPV_CONF_PATH` definition.

## Lua scripts

You can copy and install each script below to your **mpv** scripts directory,
which is usually `~/.config/mpv/scripts/` or `%APPDATA%/mpv/scripts/`. Please
see [https://mpv.io/manual/master/#files](https://mpv.io/manual/master/#files)
and [https://mpv.io/manual/master/#script-location](https://mpv.io/manual/master/#script-location)
for more information.

### [copy-and-paste.lua](https://github.com/9beach/mpv-config/blob/main/scripts/copy-and-paste.lua)

This script gives **mpv** the capability to copy and paste file paths and URLs.
You can paste and play multiple lines of media file paths, media URLs, and
HTML page URLs including YouTube, Twitter, Twitch.tv, Naver, Kakao...

You can edit key bindings below in `script-opts/copy-and-paste.conf`:

- Pastes file paths or URLs in clipboard to playlist. (`Alt+V, Ctrl+V, Meta+V`)
- Appends file paths or URLs in clipboard to playlist. (`Alt+b, Ctrl+b, Meta+b`)
- Appends file paths or URLs in clipboard to current track.
  (`Alt+v, Ctrl+v, Meta+v`)
- Copies file path or URL of current track. (`Alt+c, Ctrl+c, Meta+c`)

Please notice that:

1. To play and download media from URLs with **mpv**, you need to install
   [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases). For 
   _Microsoft Windows_ users, download
   [yt-dlp.exe](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe)
   and copy it to `C:\Windows`.
2. For _OSX_ users, when option key pressed, the context menu of a file
   reveals `Copy as pathname` menu item (or just press `⌘⌥C`). You
   can paste the pull paths of local media to **mpv** with this.

### [web-download.lua](https://github.com/9beach/mpv-config/blob/main/scripts/web-download.lua)

With this script, you can download media files of **mpv** playlist from web
sites including YouTube, Twitter, Twitch.tv, Naver, Kakao...

You can edit key bindings below in `script-opts/web-download.conf`:

- Downloads currently playing media. (`Alt+d, Ctrl+d, Meta+d`)
- Downloads all media of **mpv** playlist. (`Alt+D, Ctrl+D, Meta+D`)
- Downloads currently playing media as a audio file. (`Alt+e, Ctrl+e, Meta+e`)
- Downloads all media of **mpv** playlist as audio files.
  (`Alt+E, Ctrl+E, Meta+E`)
- Downloads currently playing media with alternative option.
  (`Alt+y, Ctrl+y, Meta+y`)
- Downloads all media of **mpv** playlist with alternative option.
  (`Alt+Y, Ctrl+Y, Meta+Y`)

To play and download media files from URLs, you need to install
[yt-dlp](https://github.com/yt-dlp/yt-dlp/releases). For _Microsoft Windows_
users, download
[yt-dlp.exe](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe)
and copy it to `C:\Windows`.

To download the highest resolution videos, and preserve chapter markers,
you need to install [ffmpeg](https://ffmpeg.org).

### [simple-playlist.lua](https://github.com/9beach/mpv-config/blob/main/scripts/simple-playlist.lua)

This script provides script messages below:

- script-message simple-playlist sort name-asc (`Alt+n, Ctrl+n, Meta+n`)
- script-message simple-playlist sort name-asc startover
  (`Alt+N, Ctrl+N, Meta+N`)
- script-message simple-playlist sort date-desc (`Alt+g, Ctrl+g, Meta+g`)
- script-message simple-playlist sort date-desc startover
  (`Alt+G, Ctrl+G, Meta+G`)

`simple-playlist sort` also support `size-asc`, `size-desc`, `date-asc`,
`name-desc` with or without `startover`. It's quite fast. Of course,
the time complexity of my sorting algorithm is **O(nlog n)** for **Lua** data,
but for the **mpv** system call, i.e., `mp.commandv('playlist-move', i, j)`,
the time complexity is **O(n)**.

- script-message simple-playlist shuffle (`Alt+s, Ctrl+s, Meta+s`)
- script-message simple-playlist reverse (`Alt+V, Ctrl+V, Meta+V`)
- script-message simple-playlist show-text 5 (`Alt+p, Ctrl+p, Meta+p`)
- script-message simple-playlist show-osc 5 (`Alt+l, Ctrl+l, Meta+l`)
- script-message simple-playlist hide (`Alt+k, Ctrl+k, Meta+k`)
- script-message simple-playlist playfirst (`Alt+a, Ctrl+a, Meta+a`)
- script-message simple-playlist playlast (`Alt+z, Ctrl+z, Meta+z`)
- script-message simple-playlist save (`Alt+P, Ctrl+P, Meta+P`)

`5` in `show-text` and `show-osc` is the duration in seconds. To keep the code
simple, the playlist is not refreshed automatically, so another `show-text` or
`show-osc` is needed to refresh the playlist.

You can edit key bindings in `input.conf`.

Many parts in my code are from <https://github.com/jonniek/mpv-playlistmanager>.

### [on-file-loaded.lua](https://github.com/9beach/mpv-config/blob/main/scripts/on-file-loaded.lua)

This script provides the functions below:

- Shows OSC always when an audio file (that is of known audio extensions or
  has no video) is loaded.
- Plays even in paused state when a new file is loaded.
- Does not show subtitle if lower-case path matches given patterns.
- Does not show subtitle if audio language matches given values.
- Resets **mpv** geometry when an non-audio file (that is not of known audio
  extensions and has video) is loaded. When you turn on this feature, **mpv**
  can escape from small rectangle when a `webm` media has video even if 
  `mpv.conf` has settings below.

  ```
  [extension.webm]
  geometry=800x800+100%+100%
  ```

`watch_later` setting for each file overrides subtitle visibilities above.
So if you change the visibility of subtitle in a file, **mpv** remembers it
just for that file if you resume to play it.

You can edit the settings in `script-opts/on-file-loaded.conf`.

### [finder-integration.lua](https://github.com/9beach/mpv-config/blob/main/scripts/finder-integration.lua)

This script provides two script messages:

1. `reveal-in-finder` runs `explorer.exe`/`Finder.app`/`Nautilus` with 
   currently playing file selected. (`Ctrl+f, Alt+f, Meta+f`)
2. `touch-file` updates the modification time of currently playing file. If you
   want to mark it to delete later or do something else with, it will help you.
   (`Ctrl+x, Alt+x, Meta+x`)

You can edit the settings in `script-opts/finder-integration.conf`.

### [on-startup-shutdown.lua](https://github.com/9beach/mpv-config/blob/master/scripts/on-startup-shutdown.lua)

This script provides the functions below:

- Saves and restores sound volume level automatically.

`watch_later` setting for each file overrides sound volume level above.
So if you change the sound volume level of a file, **mpv** remembers it just
for that file if you resume to play it.

You can edit the settings in `script-opts/on-startup-shutdown.lua`.

### [modernx-and-quotes.lua](https://github.com/9beach/mpv-config/blob/main/scripts/modernx-and-quotes.lua)

The original code is from [ModernX](https://github.com/cyl0/ModernX).

> An MPV OSC script based on
> [mpv-osc-modern](https://github.com/maoiscat/mpv-osc-modern/) that aims to
> mirror the functionality of MPV's stock OSC while with a more modern-looking
> interface.

![img](https://github.com/cyl0/ModernX/blob/main/preview.png?raw=true)

I added a simple feature. In idle state, it shows a quote about writing and art.
You can copy the text with `script-message copy-quote`, and also add your
favorite quotes to `script-opts/modernx-and-quotes.txt` file.

![img](modernx-and-quotes.png)

To install **modernx-and-quotes**, please copy `scripts/modernx-and-quotes.lua`,
`script-opts/osc.conf`, and `script-opts/modernx-and-quotes.txt` to your system.

### [autoload-ex.lua](https://github.com/9beach/mpv-config/blob/main/scripts/autoload-ex.lua)

The original code is from [mpv-player/mpv](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua).

> This script automatically loads playlist entries before and after the the
> currently played file. It does so by scanning the directory a file is located
> in when starting playback.

This script adds a simple feature to well-known `autoload.lua`.

- `disabled=yes` as default value.
- Adds a script message and keybinds, `find-and-add-files` and 
  `Ctrl+j, Alt+j, Meta+j`. So you can add all the files from the folder of 
  currently playing file with the hot keys. If you want it automatically, 
  set `disabled=no`.
