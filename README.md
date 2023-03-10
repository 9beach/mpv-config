# My mpv configuration

This repository contains several [Lua](http://lua.org) scripts and settings
I wrote for [mpv](https://mpv.io). Many parts in my code are from internet
obviously.

## Lua scripts

You can copy and install each script below to your **mpv** scripts directory,
which is usually `~/.config/mpv/scripts/` or `%APPDATA%/mpv/scripts/`. Please
see [https://mpv.io/manual/master/#files](https://mpv.io/manual/master/#files)
and [https://mpv.io/manual/master/#script-location](https://mpv.io/manual/master/#script-location)
for more information.

### [finder-integration.lua](https://github.com/9beach/mpv-config/blob/main/scripts/finder-integration.lua)

This script provides two script messages:

1. `reveal-in-finder` runs explorer.exe/Finder.app/Nautilus with playing file
   selected. If you want to reveal playing file in explorer.exe, it will help
   you.
2. `touch-file` changes the `mdate` of playing file to current time. If you
   want to mark playing file to delete later or do something else with, it will
   help you.

You can edit key bindings in `script-opts/finder-integration.conf`.

### [copy-and-paste.lua](https://github.com/9beach/mpv-config/blob/main/scripts/copy-and-paste.lua)

This script gives **mpv** the capability to copy and paste file paths and URLs.
You can paste and play multiple lines of media file paths, media URLs, and
HTML page URLs including YouTube, Twitter, Twitch.tv, Naver, Kakao...

You can edit key bindings below in `script-opts/copy-and-paste.conf`:

- Pastes file paths or URLs in clipboard to playlist. (`Ctrl+v, Meta+v`)
- Appends file paths or URLs in clipboard to playlist. (`Ctrl+V, Meta+V`)
- Appends file paths or URLs in clipboard to current track. (`Ctrl+b, Meta+b`)
- Copies file path or URL of current track. (`Ctrl+c, Meta+c`)

To play media from their URLs, you need to install
[yt-dlp](https://github.com/yt-dlp/yt-dlp/releases) in your system. For
_Microsoft Windows_ users, just copy `yt-dlp.exe` to `C:\Windows` or **mpv** 
directory.

For _OSX_ users, it's nice to know that when option key pressed, the context
menu of a file reveals `Copy as pathname` menu item (or just press `⌘⌥C`).

### [simple-playlist.lua](https://github.com/9beach/mpv-config/blob/main/scripts/simple-playlist.lua)

This script provides script messages below:

- script-message simple-playlist sort date-desc
- script-message simple-playlist sort date-asc
- script-message simple-playlist sort date-desc startover

`simple-playlist sort` also support `size-asc`, `size-desc`, `name-asc`,
`name-desc` with or without `startover`.

- script-message simple-playlist shuffle
- script-message simple-playlist reverse
- script-message simple-playlist show-text 5
- script-message simple-playlist show-osc 5
- script-message simple-playlist hide
- script-message simple-playlist playfirst
- script-message simple-playlist playlast
- script-message simple-playlist save

`5` in `show-text` and `show-osc` is the duration in seconds. To keep the code
simple, the playlist is not refreshed automatically, so another `show-text` or
`show-osc` is needed to refresh the playlist. You can edit key bindings in
`input.conf`.

Many parts in my code are from <https://github.com/jonniek/mpv-playlistmanager>
and <https://github.com/zsugabubus/dotfiles/blob/master/.config/mpv/scripts/playlist-filtersort.lua>.

### [on-file-loaded.lua](https://github.com/9beach/mpv-config/blob/main/scripts/on-file-loaded.lua)

This script provides functions below:

* Plays even in paused state when a new file is loaded.
* Shows OSC alwalys when an audio file is loaded.
* Does not show subtitle if lower-case path matches given patterns.
* Does not show subtitle if audio language matches given values.

`watch_later` settings override subtitle visibilities obove.

You can edit the configuration in `script-opts/on-file-loaded.conf`.

### [on-startup-shutdown.lua](https://github.com/9beach/mpv-config/blob/master/scripts/on-startup-shutdown.lua)

This script provides the functions below:

* Saves and restores sound volume level

You can edit the configuration in `script-opts/on-startup-shutdown.lua`.

### [modernx-and-quotes.lua](https://github.com/9beach/mpv-config/blob/main/scripts/modernx-and-quotes.lua)

The original code is from [ModernX](https://github.com/cyl0/ModernX).

> An MPV OSC script based on
> [mpv-osc-modern](https://github.com/maoiscat/mpv-osc-modern/) that aims to
> mirror the functionality of MPV's stock OSC while with a more modern-looking
> interface.

![img](https://github.com/cyl0/ModernX/blob/main/preview.png?raw=true)

I added a simple feature. In idle state, it shows a qoute about writing and art.
You can copy the text with `script-message copy-quote`, and also add your
favorite qoutes to `script-opts/modernx-and-quotes.txt` file.

![img](modernx-and-quotes.png)

To install **modernx-and-quotes**, please copy `scripts/modernx-and-quotes.lua`,
`script-opts/osc.conf`, and `script-opts/modernx-and-quotes.txt` to your system.

### autoload.lua

This code is from [mpv-player/mpv](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua). Nothing changed.

> This script automatically loads playlist entries before and after the the
> currently played file. It does so by scanning the directory a file is located
> in when starting playback.

## Installation

You can copy and install each Lua script above individually. Please notice that
the installation script below is probably just for me, and also that subtitle 
settings of `mpv.conf` and `script-opts/on-file-loaded.conf` are for Koreans.
Anyhow it installs all the scripts and configurations of this repository.

First [install mpv](https://mpv.io/installation/) and then download and unzip
[this repository](https://github.com/9beach/mpv-config/archive/refs/heads/main.zip).

In Mac or Linux, run the following from the terminal. Then it will install
`my-config` to your **mpv** configuration directory. Your original **mpv**
configuration will be copied to `~/Downloads` directory if it exists.

```console
cd mpv-config-main
./install.sh
```

If your machine has NVIDIA GPU installed, run `./install.sh nvidia`.

In _Microsoft Windows_, run the following from the `Command Prompt` or
`PowerShell`.

```console
C:\path-to\mpv-config-main> install.bat
```

If your machine has NVIDIA GPU installed, run `install.bat nvidia`.
