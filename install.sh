#!/bin/bash

cd "$(dirname "$0")"

case "$(uname -sr)" in

  Darwin*)
    PLATFORM='darwin'
    ;;

  Linux*Microsoft*)
    PLATFORM='wsl'
    ;;

  Linux*)
    PLATFORM='linux'
    ;;

  CYGWIN*|MINGW*|MINGW32*|MSYS*)
    PLATFORM='windows'
    ;;

esac

# If your machine has NVIDIA GPU installed, run `./install.sh nvidia`.
if [ "$PLATFORM" = "windows" ] || [ "$PLATFORM" = "wsl" ]; then

	if [ "$PLATFORM" = "wsl" ]; then
		MY_HOME=`wslpath -a "$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null)"`
	else
		MY_HOME=$HOME
	fi
	if [ "$MPV_CONF_PATH" = "" ]; then
		MPV_CONF_PATH="$MY_HOME/AppData/Roaming/mpv"
	fi
	if [ "$1" = "nvidia" ]; then
		my_filter() {
			grep -v "^# *osx *:" | sed -e "s/^# *nvidia *://"
		}
	else
		my_filter() {
			grep -v '^# *osx *:' | grep -v '^# *nvidia *:'
		}
	fi
elif [ `uname` = "Darwin" ]; then
	if [ "$MPV_CONF_PATH" = "" ]; then
		MPV_CONF_PATH="$HOME/.config/mpv"
	fi
	my_filter() {
		grep -v '^# *nvidia *:' | sed -e 's/^# *osx *://'
	}
else
	if [ "$MPV_CONF_PATH" = "" ]; then
		MPV_CONF_PATH="$HOME/.config/mpv"
	fi
	if [ "$1" = "nvidia" ]; then
		my_filter() {
			grep -v '^# *osx *:' | sed -e 's/^# *nvidia *://'
		}
	else
		my_filter() {
			grep -v '^# *osx *:' | grep -v '^# *nvidia *:'
		}
	fi
fi

BACKUP_DIR="$HOME/Downloads/mpv-$(date "+%m%d%H%M%Y.%S")"

mv "$MPV_CONF_PATH" "$BACKUP_DIR" 2> /dev/null \
	&& echo "old mpv config to \"$BACKUP_DIR\""

mkdir -p "$MPV_CONF_PATH"
cp -R fonts script-opts scripts input.conf "$MPV_CONF_PATH"

# By setting `ytdl=no` and copying `osx-scripts/ytdl_hook.lua` to
# `scripts`, applies patched `ytdl_hook.lua` over **mpv** internal version
# before patched OSX **mpv** releases.
if [ `uname` = "Darwin" ]; then
	cp -R osx-scripts/ytdl_hook.lua "$MPV_CONF_PATH/scripts"
fi
cat mpv.conf | my_filter > "$MPV_CONF_PATH"/mpv.conf
mv "$BACKUP_DIR/watch_later" "$MPV_CONF_PATH" 2> /dev/null
echo "new mpv config to \"$MPV_CONF_PATH\""
