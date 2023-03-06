# My mpv configuration

This repository contains several [Lua](http://lua.org) scripts and settings
for [mpv](https://mpv.io). I wrote `finder-integration.lua`,
`copy-and-paste.lua`, `simple-playlist.lua` and `on-file-loaded.lua`. But many
parts in my scripts are from internet.

## Lua scripts

You can copy and install each script below to your mpv scripts directory, which
is usually `~/.config/mpv/scripts/` or `%APPDATA%/mpv/scripts/`. Please see
[https://mpv.io/manual/master/#files](https://mpv.io/manual/master/#files) and
[https://mpv.io/manual/master/#script-location](https://mpv.io/manual/master/#script-location) for more information.

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

This script gives mpv the capability to copy and paste file paths and URLs.

You can edit key bindings in `script-opts/copy-and-paste.conf`.

### [simple-playlist.lua](https://github.com/9beach/mpv-config/blob/main/scripts/simple-playlist.lua)

This script provides script messages below:

* script-message simple-playlist sort date-desc
* script-message simple-playlist sort date-asc
* script-message simple-playlist sort date-desc startover

`simple-playlist sort` also support `size-asc`, `size-desc`, `name-asc`,
`name-desc` with or without `startover`.

* script-message simple-playlist shuffle
* script-message simple-playlist reverse
* script-message simple-playlist show-text
* script-message simple-playlist show-osc
* script-message simple-playlist hide
* script-message simple-playlist toggle-show-text
* script-message simple-playlist toggle-show-osc
* script-message simple-playlist playfirst
* script-message simple-playlist playlast
* script-message simple-playlist save

You can edit key bindings in `input.conf`.

Many parts in the code are from <https://github.com/jonniek/mpv-playlistmanager>
and <https://github.com/zsugabubus/dotfiles/blob/master/.config/mpv/scripts/playlist-filtersort.lua>.

### [on-file-loaded.lua](https://github.com/9beach/mpv-config/blob/main/scripts/on-file-loaded.lua)

This script has two functionalities:

1. Plays even in paused state when a new file is loaded.
2. Shows OSC always when an audio file is loaded.

### [modernx-and-quotes.lua](https://github.com/9beach/mpv-config/blob/main/scripts/modernx-and-quotes.lua)

The original code is from [ModernX](https://github.com/cyl0/ModernX).

> An MPV OSC script based on
> [mpv-osc-modern](https://github.com/maoiscat/mpv-osc-modern/) that aims to
> mirror the functionality of MPV's stock OSC while with a more modern-looking
> interface.

![img](https://github.com/cyl0/ModernX/blob/main/preview.png?raw=true)

I added a simple feature. In idle state, it shows a qoute about writing and art.
You can copy the text with `script-message copy-quote`, and also add your
favorite qoutes to `writing-quotes` file.

![img](writing-quotes.png)

### autoload.lua

This code is from [mpv-player/mpv](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua). Nothing changed.

> This script automatically loads playlist entries before and after the the
> currently played file. It does so by scanning the directory a file is located
> in when starting playback.

## Installation

You can copy and install each Lua script above. The installation script below
is probably just for me. It installs all the scripts and configurations of
this repo.

First [install mpv](https://mpv.io/installation/) and then download and unzip
[this repo](https://github.com/9beach/mpv-config/archive/refs/heads/main.zip).

In Mac or Linux, run the following from the terminal. Then it will install
`my-config` to your mpv configuration directory. Your original mpv
configuration will be copied to `~/Downloads` directory if it exists.

```console
cd mpv-config-main
./install.sh
```

In Microsoft Windows, run the following from the `Command Prompt` or
`PowerShell`.

```console
C:\path-to\mpv-config-main> install.bat
```

**WARNING!** My Windows machine has NVIDIA GPU installed. So if yours does not
have it. Please remove 10 or more lines below `# Video` in `mpv.conf`.
