update_android_cmdline() {

	# Update package
	cmdline="$HOME/Android/Sdk/cmdline-tools"
	if [[ ! -d $cmdline ]]; then
		mkdir -p "$cmdline"
		website="https://developer.android.com/studio#command-tools"
		pattern="commandlinetools-win-\K(\d+)"
		version="$(curl -s "$website" | grep -oP "$pattern" | head -1)"
		address="https://dl.google.com/android/repository"
		address="$address/commandlinetools-linux-${version}_latest.zip"
		archive="$(mktemp -d)/$(basename "$address")"
		curl -LA "Mozilla/5.0" "$address" -o "$archive"
		unzip -d "$cmdline" "$archive"
		yes | $cmdline/cmdline-tools/bin/sdkmanager "cmdline-tools;latest"
		rm -rf "$cmdline/cmdline-tools"
	fi

	# Change environment
	configs="$HOME/.bashrc"
	if ! grep -q "ANDROID_HOME" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >>"$configs"
		export ANDROID_HOME="$HOME/Android/Sdk"
		export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
		export PATH="$PATH:$ANDROID_HOME/emulator"
		export PATH="$PATH:$ANDROID_HOME/platform-tools"
	fi

}

update_android_studio() {

	# Handle parameters
	release=${1:-stable}
	deposit=${2:-$HOME/Projects}

	# Update dependencies
	sudo dnf install -y bzip2-libs.i686 ncurses-libs.i686 zlib.i686
	sudo dnf install -y bridge-utils libvirt qemu-kvm virt-install

	# Update package
	[[ $release = sta* || $release = beta* || $release = can* ]] || return 1
	[[ $release = sta* ]] && payload="android-studio"
	[[ $release = bet* ]] && payload="android-studio-beta"
	[[ $release = can* ]] && payload="android-studio-canary"
	address="https://aur.archlinux.org/packages/$payload"
	pattern="android-studio.* \K(\d.+)(?=-)"
	version=$(curl -s "$address" | grep -oP "$pattern" | head -1)
	current=""
	updated=false
	if [[ $updated == false ]]; then
		address="https://dl.google.com/dl/android/studio/ide-zips/$version/android-studio-$version-linux.tar.gz"
		package="$(mktemp -d)/$(basename "$address")"
		curl -LA "Mozilla/5.0" "$address" -o "$package"
		sudo rm -r "/opt/$payload"
		tempdir="$(mktemp -d)" && sudo tar -xvf "$package" -C "$tempdir"
		sudo mv -f "$tempdir/android-studio" "/opt/$payload"
		sudo ln -fs "/opt/$payload/bin/studio.sh" "/bin/$payload"
		source "$HOME/.bashrc"
	fi

	# Create desktop
	sudo rm "/usr/share/applications/jetbrains-studio.desktop"
	desktop="/usr/share/applications/$payload.desktop"
	cat /dev/null | sudo tee "$desktop"
	echo "[Desktop Entry]" | sudo tee -a "$desktop"
	echo "Version=1.0" | sudo tee -a "$desktop"
	echo "Type=Application" | sudo tee -a "$desktop"
	echo "Name=Android Studio" | sudo tee -a "$desktop"
	echo "Icon=androidstudio" | sudo tee -a "$desktop"
	echo "Exec=\"/opt/$payload/bin/studio.sh\" %f" | sudo tee -a "$desktop"
	echo "Comment=The Drive to Develop" | sudo tee -a "$desktop"
	echo "Categories=Development;IDE;" | sudo tee -a "$desktop"
	echo "Terminal=false" | sudo tee -a "$desktop"
	echo "StartupWMClass=jetbrains-studio" | sudo tee -a "$desktop"
	echo "StartupNotify=true" | sudo tee -a "$desktop"
	[[ $release = bet* ]] && sudo sed -i "s/Name=.*/Name=Android Studio Beta/" "$desktop"
	[[ $release = can* ]] && sudo sed -i "s/Icon=.*/Icon=androidstudio-canary/" "$desktop"
	[[ $release = can* ]] && sudo sed -i "s/Name=.*/Name=Android Studio Canary/" "$desktop"

	# Finish installation
	update_android_cmdline
	yes | sdkmanager "build-tools;33.0.1"
	yes | sdkmanager "emulator" # TODO: Install emulator preview if required
	yes | sdkmanager "platform-tools"
	yes | sdkmanager "platforms;android-32"
	yes | sdkmanager "platforms;android-33"
	yes | sdkmanager "sources;android-33"
	yes | sdkmanager "system-images;android-33;google_apis;x86_64"
	avdmanager create avd -n "Pixel_3_API_33" -d "pixel_3" -k "system-images;android-33;google_apis;x86_64" &>/dev/null

	# TODO: Change settings
	# update_jetbrains_config "Android" "directory" "$deposit"
	# update_jetbrains_config "Android" "font_size" "14"
	# update_jetbrains_config "Android" "line_size" "1.5"
	# [[ $release = can* ]] && update_jetbrains_config "AndroidPreview" "newest_ui" "true"

}

update_chromium() {

	# Handle parameters
	cleaned=${1:-true}
	deposit=${2:-$HOME/Downloads}
	startup=${3:-about:blank}

	# Update dependencies
	sudo dnf install -y curl jq ydotool

	# Update package
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install -y flathub com.github.Eloston.UngoogledChromium

	# Change environment
	configs="$HOME/.bashrc"
	if ! grep -q "CHROME_EXECUTABLE" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export CHROME_EXECUTABLE="/usr/bin/chromium-freeworld"' >>"$configs"
		export CHROME_EXECUTABLE="/usr/bin/chromium-freeworld"
	fi

}

update_chromium_extension() {

	payload=${2}

}

update_flutter() {

	# Update flutter
	deposit="$HOME/Android/Flutter" && mkdir -p "$deposit"
	git clone "https://github.com/flutter/flutter.git" -b stable "$deposit"

	# Adjust environment
	configs="$HOME/.bashrc"
	if ! grep -q "Flutter" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export PATH="$PATH:$HOME/Android/Flutter/bin"' >>"$configs"
		export PATH="$PATH:$HOME/Android/Flutter/bin"
	fi

	# Finish installation
	dart --disable-analytics
	flutter config --no-analytics
	flutter precache && flutter upgrade
	yes | flutter doctor --android-licenses

	# TODO: Update android-studio extensions
	# update_jetbrains_plugin "AndroidStudio" "6351"  # Dart
	# update_jetbrains_plugin "AndroidStudio" "9212"  # Flutter

	# Update vscode extensions
	code --install-extension "dart-code.flutter" &>/dev/null
	code --install-extension "RichardCoutts.mvvm-plus" &>/dev/null
	

}

update_git() {

	# Handle parameters
	default=${1:-master}
	gitmail=${2:-anonymous@example.com}
	gituser=${3:-anonymous}

	# Update package
	sudo dnf install -y git

	# Change settings
	git config --global credential.helper "store"
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"
	git config --global user.email "$gitmail"
	git config --global user.name "$gituser"

}

update_jdownloader() {

	deposit=${1:-$HOME/Downloads/JD2}

	# Update dependencies
	sudo dnf install -y flatpak jq moreutils
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	# Update jdownloader
	flatpak install --assumeyes flathub org.jdownloader.JDownloader

	# Create deposit
	mkdir -p "$deposit"

	# Change desktop
	desktop="/var/lib/flatpak/exports/share/applications/org.jdownloader.JDownloader.desktop"
	sudo sed -i 's/Icon=.*/Icon=jdownloader/' "$desktop"

	# Change settings
	appdata="$HOME/.var/app/org.jdownloader.JDownloader/data/jdownloader"
	config1="$appdata/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
	config2="$appdata/cfg/org.jdownloader.settings.GeneralSettings.json"
	config3="$appdata/cfg/org.jdownloader.gui.jdtrayicon.TrayExtension.json"
	(flatpak run org.jdownloader.JDownloader >/dev/null 2>&1 &) && sleep 8
	while [[ ! -f "$config1" ]]; do sleep 2; done
	flatpak kill org.jdownloader.JDownloader && sleep 8
	jq ".bannerenabled = false" "$config1" | sponge "$config1"
	jq ".donatebuttonlatestautochange = 4102444800000" "$config1" | sponge "$config1"
	jq ".donatebuttonstate = \"AUTO_HIDDEN\"" "$config1" | sponge "$config1"
	jq ".myjdownloaderviewvisible = false" "$config1" | sponge "$config1"
	jq ".premiumalertetacolumnenabled = false" "$config1" | sponge "$config1"
	jq ".premiumalertspeedcolumnenabled = false" "$config1" | sponge "$config1"
	jq ".premiumalerttaskcolumnenabled = false" "$config1" | sponge "$config1"
	jq ".specialdealoboomdialogvisibleonstartup = false" "$config1" | sponge "$config1"
	jq ".specialdealsenabled = false" "$config1" | sponge "$config1"
	jq ".speedmetervisible = false" "$config1" | sponge "$config1"
	jq ".defaultdownloadfolder = \"$deposit\"" "$config2" | sponge "$config2"
	jq ".enabled = false" "$config3" | sponge "$config3"

}

update_jetbrains_config() {

	# Handle parameters
	pattern=${1}
	element=${2}
	content=${3}

	# Verify parameters
	factors=(project-dir font_size line_size newest_ui)
	[[ -z "$content" || -z "$pattern" || ! "${factors[*]}" =~ $element ]] && return 1

	# Update dependencies
	sudo dnf install -y xmlstarlet

	# Gather topmost directory
	deposit=$(find $HOME/.config/*/*$pattern* -maxdepth 0 2>/dev/null | sort -r | head -1)

	# Update project directory
	if [[ $element = "directory" ]]; then
		configs=$(ls $deposit/options/ide.general.xml)
		if [[ -z "$(xmlstarlet sel -t -v "//*[@name='GeneralSettings']/@name" "$configs")" ]]; then
			xmlstarlet ed -L -s "/application" \
				-t "elem" -n "new-component" -v "" \
				-i "/application/new-component" \
				-t "attr" -n "name" -v "GeneralSettings" \
				-r "/application/new-component" -v "component" "$configs"
		fi
		if [[ -z "$(xmlstarlet sel -t -v "//*[@name='defaultProjectDirectory']/@name" "$configs")" ]]; then
			xmlstarlet ed -L -s "/application/component[@name='GeneralSettings']" \
				-t "elem" -n "new-option" -v "" \
				-i "/application/component[@name='GeneralSettings']/new-option" \
				-t "attr" -n "name" -v "defaultProjectDirectory" \
				-i "/application/component[@name='GeneralSettings']/new-option" \
				-t "attr" -n "value" -v "$content" \
				-r "/application/component[@name='GeneralSettings']/new-option" -v "option" "$configs"
		else
			xmlstarlet ed -L -u "//*[@name='defaultProjectDirectory']/@value" -v "$content" "$configs"
		fi
	fi

	# Update font size
	if [[ $element = "font_size" ]]; then
		configs=$(ls $deposit/options/editor-font.xml)
		[[ -s "$configs" ]] || echo "<application />" >"$configs"
		if [[ -z "$(xmlstarlet sel -t -v "//*[@name='DefaultFont']/@name" "$configs")" ]]; then
			xmlstarlet ed -L -s "/application" \
				-t "elem" -n "new-component" -v "" \
				-i "/application/new-component" \
				-t "attr" -n "name" -v "DefaultFont" \
				-r "/application/new-component" -v "component" "$configs"
		fi
		if [[ -z "$(xmlstarlet sel -t -v "//*[@name='FONT_SIZE']/@name" "$configs")" ]]; then
			xmlstarlet ed -L -s "/application/component[@name='DefaultFont']" \
				-t "elem" -n "new-option" -v "" \
				-i "/application/component[@name='DefaultFont']/new-option" \
				-t "attr" -n "name" -v "FONT_SIZE" \
				-i "/application/component[@name='DefaultFont']/new-option" \
				-t "attr" -n "value" -v "$content" \
				-r "/application/component[@name='DefaultFont']/new-option" -v "option" "$configs"
		else
			xmlstarlet ed -L -u "//*[@name='FONT_SIZE']/@value" -v "$content" "$configs"
		fi
		if [[ -z "$(xmlstarlet sel -t -v "//*[@name='FONT_SIZE_2D']/@name" "$configs")" ]]; then
			xmlstarlet ed -L -s "/application/component[@name='DefaultFont']" \
				-t "elem" -n "new-option" -v "" \
				-i "/application/component[@name='DefaultFont']/new-option" \
				-t "attr" -n "name" -v "FONT_SIZE_2D" \
				-i "/application/component[@name='DefaultFont']/new-option" \
				-t "attr" -n "value" -v "$content" \
				-r "/application/component[@name='DefaultFont']/new-option" -v "option" "$configs"
		else
			xmlstarlet ed -L -u "//*[@name='FONT_SIZE_2D']/@value" -v "$content" "$configs"
		fi
	fi

	# Update line height
	if [[ $element = "line_size" ]]; then
		[[ -s "$configs" ]] || echo "<application />" >"$configs"
		if [[ -z "$(xmlstarlet sel -t -v "//*[@name='DefaultFont']/@name" "$configs")" ]]; then
			xmlstarlet ed -L -s "/application" \
				-t "elem" -n "new-component" -v "" \
				-i "/application/new-component" \
				-t "attr" -n "name" -v "DefaultFont" \
				-r "/application/new-component" -v "component" "$configs"
		fi
		if [[ -z "$(xmlstarlet sel -t -v "//*[@name='LINE_SPACING']/@name" "$configs")" ]]; then
			xmlstarlet ed -L -s "/application/component[@name='DefaultFont']" \
				-t "elem" -n "new-option" -v "" \
				-i "/application/component[@name='DefaultFont']/new-option" \
				-t "attr" -n "name" -v "LINE_SPACING" \
				-i "/application/component[@name='DefaultFont']/new-option" \
				-t "attr" -n "value" -v "$content" \
				-r "/application/component[@name='DefaultFont']/new-option" -v "option" "$configs"
		else
			xmlstarlet ed -L -u "//*[@name='LINE_SPACING']/@value" -v "$content" "$configs"
		fi
	fi

	# # Enable experimental ui
	# if [[ $element = "newest_ui" ]]; then
	# 	configs=$(ls $deposit/options/ide.general.xml)
	# 	if [[ -z "$(xmlstarlet sel -t -v "//*[@name='Registry']/@name" "$configs")" ]]; then
	# 		xmlstarlet ed -L -s "/application" \
	# 			-t "elem" -n "new-component" -v "" \
	# 			-i "/application/new-component" \
	# 			-t "attr" -n "name" -v "Registry" \
	# 			-r "/application/new-component" -v "component" "$configs"
	# 	fi
	# 	if [[ -z "$(xmlstarlet sel -t -v "//*[@key='ide.experimental.ui']/@key" "$configs")" ]]; then
	# 		xmlstarlet ed -L -s "/application/component[@name='Registry']" \
	# 			-t "elem" -n "new-entry" -v "" \
	# 			-i "/application/component[@name='Registry']/new-entry" \
	# 			-t "attr" -n "key" -v 'ide.experimental.ui' \
	# 			-i "/application/component[@name='Registry']/new-entry" \
	# 			-t "attr" -n "value" -v "$content" \
	# 			-r "/application/component[@name='Registry']/new-entry" -v "entry" "$configs"
	# 	else
	# 		xmlstarlet ed -L -u "//*[@key='ide.experimental.ui']/@value" -v "$content" "$configs"
	# 	fi
	# fi

}

update_jetbrains_plugin() {

	# Handle parameters
	pattern=${1}
	element=${2}

	# Update dependencies
	sudo dnf install -y jq

	# Gather topmost directory
	deposit=$(find $HOME/.config/*/*$pattern* -maxdepth 0 2>/dev/null | sort -r | head -1)
	[[ -d $deposit ]] || return 0

}

update_scrcpy() {

	# Update package
	sudo dnf copr enable -y zeno/scrcpy
	sudo dnf install -y scrcpy

}

update_system() {

	# Change extensions
	gnome-extensions disable background-logo@fedorahosted.org
	gnome-extensions enable places-menu@gnome-shell-extensions.gcampax.github.com

	# Change font rendering
	gsettings set org.gnome.desktop.interface font-antialiasing "rgba"
	gsettings set org.gnome.desktop.interface font-hinting "slight"

	# Change font
	sudo dnf install -y cascadia-fonts-all
	gsettings set org.gnome.desktop.interface monospace-font-name "Cascadia Mono PL Semi-Bold 10"
	# gsettings set org.gnome.desktop.interface monospace-font-name "Roboto Mono Medium 10"
	# gsettings set org.gnome.desktop.interface monospace-font-name "Source Code Pro Semi-Bold 10"

	# Change icons
	sudo dnf install -y papirus-icon-theme
	gsettings set org.gnome.desktop.interface icon-theme "Papirus"

	# Enable remote desktop
	systemctl --user enable --now gnome-remote-desktop.service
	gsettings set org.gnome.desktop.remote-desktop.rdp tls-cert "$HOME/.local/share/gnome-remote-desktop/rdp-tls.crt"
	gsettings set org.gnome.desktop.remote-desktop.rdp tls-key "$HOME/.local/share/gnome-remote-desktop/rdp-tls.key"
	gsettings set org.gnome.desktop.remote-desktop.rdp enable true
	gsettings set org.gnome.desktop.remote-desktop.vnc view-only false

}

update_vscodium() {

	# Update dependencies
	sudo dnf install -y cascadia-fonts-all jq moreutils

	# Update package
	deposit="/etc/yum.repos.d/vscodium.repo"
	sudo rpmkeys --import "https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg"
	echo "[gitlab.com_paulcarroty_vscodium_repo]" | sudo tee "$deposit"
	echo "name=download.vscodium.com" | sudo tee -a "$deposit"
	echo "baseurl=https://download.vscodium.com/rpms/" | sudo tee -a "$deposit"
	echo "enabled=1" | sudo tee -a "$deposit"
	echo "gpgcheck=1" | sudo tee -a "$deposit"
	echo "repo_gpgcheck=1" | sudo tee -a "$deposit"
	echo "gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg" | sudo tee -a "$deposit"
	echo "metadata_expire=1h" | sudo tee -a "$deposit"
	sudo dnf install -y codium

	# Update some extensions.
	codium --install-extension "foxundermoon.shell-format"
	codium --install-extension "github.github-vscode-theme"

	# Change settings
	configs="$HOME/.config/VSCodium/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."editor.fontFamily" = "Cascadia Code, monospace"' "$configs" | sponge "$configs"
	jq '."editor.fontSize" = 13' "$configs" | sponge "$configs"
	jq '."editor.lineHeight" = 32' "$configs" | sponge "$configs"
	jq '."security.workspace.trust.enabled" = false' "$configs" | sponge "$configs"
	jq '."telemetry.telemetryLevel" = "crash"' "$configs" | sponge "$configs"
	jq '."update.mode" = "none"' "$configs" | sponge "$configs"
	jq '."window.menuBarVisibility" = "toggle"' "$configs" | sponge "$configs"
	jq '."workbench.colorTheme" = "GitHub Dark Default"' "$configs" | sponge "$configs"

	# Change inotify
	configs="/etc/sysctl.conf"
	if ! grep -q "fs.inotify.max_user_watches" "$configs"; then
		[[ -z $(tail -1 "$configs") ]] || echo "" | sudo tee -a "$configs"
		echo "fs.inotify.max_user_watches=524288" | sudo tee -a "$configs"
		sudo sysctl -p &>/dev/null
	fi

}

main() {

	# Prompt password
	sudo -v && clear

	# Remove timeout
	echo "Defaults timestamp_timeout=-1" | sudo tee "/etc/sudoers.d/disable_timeout" &>/dev/null

	# Remove screensaver
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	gsettings set org.gnome.desktop.session idle-delay 0

	# Remove notifications
	gsettings set org.gnome.desktop.notifications show-banners false

	# Change title
	printf "\033]0;%s\007" "fedhogen"

	# Output welcome
	read -r -d "" welcome <<-EOD
		███████╗███████╗██████╗░██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
		██╔════╝██╔════╝██╔══██╗██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
		█████╗░░█████╗░░██║░░██║███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
		██╔══╝░░██╔══╝░░██║░░██║██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
		██║░░░░░███████╗██████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
		╚═╝░░░░░╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD
	printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Handle functions
	factors=(
		"update_android_studio"
		# "update_android_studio canary"
		"update_chromium"
		"update_git main sharpordie@outlook.com sharpordie"
		"update_vscodium"
		"update_flutter"
		"update_jdownloader"
		"update_system"
	)

	# Output progress
	maximum=$((${#welcome} / $(echo "$welcome" | wc -l)))
	heading="\r%-"$((maximum - 20))"s   %-6s   %-8s\n\n"
	loading="\r%-"$((maximum - 20))"s   \033[93mACTIVE\033[0m   %-8s\b"
	failure="\r%-"$((maximum - 20))"s   \033[91mFAILED\033[0m   %-8s\n"
	success="\r%-"$((maximum - 20))"s   \033[92mWORKED\033[0m   %-8s\n"
	printf "$heading" "FUNCTION" "STATUS" "DURATION"
	for element in "${factors[@]}"; do
		written=$(basename "$(echo "$element" | cut -d ' ' -f 1)" | tr "[:lower:]" "[:upper:]")
		started=$(date +"%s") && printf "$loading" "$written" "--:--:--"
		eval "$element" >/dev/null 2>&1 && current="$success" || current="$failure"
		extinct=$(date +"%s") && elapsed=$((extinct - started))
		elapsed=$(printf "%02d:%02d:%02d\n" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
		printf "$current" "$written" "$elapsed"
	done

	# Revert timeout
	sudo rm "/etc/sudoers.d/disable_timeout"

	# Revert screensaver
	gsettings set org.gnome.desktop.screensaver lock-enabled true
	gsettings set org.gnome.desktop.session idle-delay 300

	# Revert notifications
	gsettings set org.gnome.desktop.notifications show-banners true

	# Output newline
	printf "\n"

}

main
