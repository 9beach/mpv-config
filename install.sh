cd "$(dirname "$0")"

# If your machine has NVIDIA GPU installed, run `./install.sh nvidia`.
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
	WINHOME=`wslpath -a "$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null)"`
	MPV_CONF_PATH="$WINHOME"/AppData/Roaming/mpv
	if [ "$1" = "nvidia" ]; then
		my_filter() {
			grep -v "^# *osx *:" | sed -e "s/^# *nvidia *://"
		}
	else
		my_filter() {
			grep -v '^# *osx *:' | grep -v '^# *nvidia *:'
		}
	fi
elif [[ `uname` == "Darwin" ]]; then
	MPV_CONF_PATH="$HOME/.config/mpv"
	my_filter() {
		grep -v '^# *nvidia *:' | sed -e 's/^# *osx *://'
	}
else
	MPV_CONF_PATH="$HOME/.config/mpv"
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
	&& echo "moved old mpv config to \"$BACKUP_DIR\""

mkdir -p "$MPV_CONF_PATH"
cp -R fonts script-opts scripts input.conf "$MPV_CONF_PATH"
cat mpv.conf | my_filter > "$MPV_CONF_PATH"/mpv.conf
mv "$BACKUP_DIR/watch_later" "$MPV_CONF_PATH" 2> /dev/null
mv "$BACKUP_DIR/.volume" "$MPV_CONF_PATH" 2> /dev/null
echo "copied new mpv config to \"$MPV_CONF_PATH\""
