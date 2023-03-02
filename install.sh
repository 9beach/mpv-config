cd "$(dirname "$0")"

if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
	WINHOME=`wslpath -a "$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null)"`
	MPV_CONF_PATH="$WINHOME"/AppData/Roaming/mpv
	GREP_PARAM='^# *osx *:'
	SED_PARAM='s/^# *windows *://'
elif [[ `uname` == "Darwin" ]]; then
	MPV_CONF_PATH="$HOME/.config/mpv"
	MY_CONF=mpv-osx.conf
	GREP_PARAM='^# *windows *:'
	SED_PARAM='s/^# *osx *://'
fi

BACKUP_DIR="$HOME/Downloads/mpv-$(date "+%m%d%H%M%Y.%S")"

mv "$MPV_CONF_PATH" "$BACKUP_DIR" 2> /dev/null \
	&& echo "moved old mpv config to \"$BACKUP_DIR\""

set -e

mkdir -p "$MPV_CONF_PATH"
cp -R fonts script-opts scripts writing-quotes input.conf "$MPV_CONF_PATH"
cat mpv.conf | grep -v "$GREP_PARAM" | sed -e "$SED_PARAM" > "$MPV_CONF_PATH"/mpv.conf
echo "copied new mpv config to \"$MPV_CONF_PATH\""
