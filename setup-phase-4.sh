#!/bin/bash

source ./env.sh
source ./helper-functions.sh

if [[ -z "$prefix" ]]; then
   echor "No prefix found inside distrobox, aborting"
   exit 1
fi

echor "Phase 4"
export STEP_INDEX=1
cd "$prefix" || {
   echor "Couldn't go into installation folder on phase 4, aborting."
   exit 1
}

# Get current gpu (and version in case if it's nvidia from configuration)
GPU="$(head <specs.conf -1 | tail -2)"
if [[ "$GPU" == nvidia* ]]; then
   GPU=$(echo "$GPU" | cut -d' ' -f1)
fi
AUDIO_SYSTEM="$(head <specs.conf -2 | tail -1)"

echog "Installing packages for base functionality."
sudo pacman -q --noprogressbar -Syu git vim base-devel noto-fonts xdg-user-dirs fuse libx264 sdl2 libva-utils xorg-server --noconfirm || exit 1

echog "Installing paru-bin"
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin || echor "Couldn't go into paru-bin folder, aborting."
makepkg --noprogressbar -si --noconfirm
cd ..

echog "Installing steam, audio and driver packages."
if [[ "$GPU" == "amd" ]]; then
   sudo pacman -q --noprogressbar -Syu libva-mesa-driver vulkan-radeon lib32-vulkan-radeon lib32-libva-mesa-driver --noconfirm || exit 1
elif [[ "$GPU" == "nvidia" ]]; then
   # TODO do something about packages that steam installs for vulkan but not needed for nvidia
   echog "Using host system driver mounts, not installing anything inside for nvidia drivers."
else
   echor "Couldn't determine gpu with name: $GPU, exiting!"
   exit 1
fi
if [[ "$AUDIO_SYSTEM" == "pipewire" ]]; then
   sudo pacman -q --noprogressbar -Syu lib32-pipewire pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber --noconfirm || exit 1
elif [[ "$AUDIO_SYSTEM" == "pulseaudio" ]]; then
   sudo pacman -q --noprogressbar -Syu pulseaudio pusleaudio-alsa --noconfirm || exit 1
else
   echor "Couldn't determine audio system: $AUDIO_SYSTEM, you may have issues with audio!"
fi

sudo pacman -q --noprogressbar -Syu steam --noconfirm --assume-installed vulkan-driver --assume-installed lib32-vulkan-driver || exit 1

export STEP_INDEX=2
sleep 2

# Ask user for installing steamvr
echog "Installed base packages and Steam. Opening steam. Please install SteamVR from it."

# Define proper steam desktop file
mkdir ~/.config
xdg-mime default steam.desktop x-scheme-handler/steam

steam steam://install/250820 &>/dev/null &
echog "Installation continues when steamvr will be installed"
echor "Huge note: currently steamvr under distrobox won't allow opening settings because it's vrwebhelper doesn't load, i don't know fix yet for that so, use wlxoverlay to open games for now"
echor "This also means some post-installation notes may not be applied for now"
while [ ! -f "$HOME/.steam/steam/steamapps/common/SteamVR/bin/vrwebhelper/linux64/vrwebhelper.sh" ]; do
   sleep 5
done
sleep 3

if [[ "$WAYLAND_DISPLAY" != "" ]]; then
   echog "Patching steam commandline options to allow proper steamvr launching on wayland."
   sed -iv 's|"LaunchOptions"[[:space:]]*""|"LaunchOptions"         "WAYLAND_DISPLAY='' %command%"|g' "$HOME/.steam/steam/userdata/80832101/config/localconfig.vdf" ||
      echor "Couldn't patch wayland display variable om steamvr commandline options, you might want to set it manually: WAYLAND_DISPLAY='' %command%"
fi

echog "Closing steam to apply commandline options"
pkill steam
sleep 3
pkill -9 steam

echog "Next prompt for superuser access prevents annoying popup from steamvr (yes/no with asking for superuser) that prevents steamvr from launching automatically."
distrobox-host-exec pkexec setcap CAP_SYS_NICE+ep "$HOME/.steam/steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher" ||
   echor "Couldn't setcap vrcompositor, steamvr will ask for permissions every single launch."

echog "Running steamvr once to generate startup files."
steam steam://run/250820 &>/dev/null &
wait_for_initial_steamvr
cleanup_alvr

echog "At this point you can safely add your existing library from your system if you had one."
echog "When ready for next step, press enter to continue."
read

export STEP_INDEX=3
sleep 2

echog "Installing alvr, compilation might take a loong time (up to 15-20 minutes or more depending on CPU)."
echog "If during compiling you think it's frozen, don't close it, it's still compiling."
echog "This installation script will download apk client for the headset later, but you shouldn't connect it to alvr during this script installation, leave it to post install."
# temporarily changed to nightly alvr until after 20.5.0
paru -q --noprogressbar -S rust alvr-git --noconfirm --assume-installed vulkan-driver --assume-installed lib32-vulkan-driver || exit 1
# clear cache, alvr targets folder might take up to 10 gb
yes | paru -q --noprogressbar -Scc || exit 1
alvr_dashboard &>/dev/null &
echog "ALVR and dashboard now launch. Proceed with setup wizard in Installation tab -> Run setup wizard and after finishing it, continue there."
echog "Setting firewall rules will fail and it's normal, not yet available to do when using this installation method."
echog "If after installation you can't seem to connect headset, then please open 9944 and 9943 ports using your system firewall."
echog "Launch SteamVR using button on left lower corner and after starting steamvr, you should see one headset showing up in steamvr menu and 'Streamer: Connected' in ALVR dashboard."
echor "After you have done with this, press enter here, and don't close alvr dashboard."
read
echog "Downloading ALVR apk, you can install it now from the $prefix folder into your headset using either ADB or Sidequest on your system."
wget -q --show-progress "$ALVR_APK_LINK" || echor "Could not download apk, please download it from $ALVR_APK_LINK manually."

STEP_INDEX=4
sleep 2

# installing wlxoverlay
echog "For using desktop from inside vr instead of broken steamvr overlay, we will install WlxOverlay."
wget -q --show-progress -O "$WLXOVERLAY_FILENAME" "$WLXOVERLAY_LINK"
chmod +x "$WLXOVERLAY_FILENAME"
if [[ "$WAYLAND_DISPLAY" != "" ]]; then
   echog "If you're not (on wlroots-based compositor like Sway), it will ask for display to choose. Choose each display individually."
fi
./"$WLXOVERLAY_FILENAME" &>/dev/null &
if [[ "$WAYLAND_DISPLAY" != "" ]]; then
   echog "If everything went well, you might see little icon on your desktop that indicates that screenshare is happening (by WlxOverlay) created by xdg portal."
fi
echog "WlxOverlay adds itself to SteamVR auto-startup."
echog "Press enter to continue."
read

STEP_INDEX=5
sleep 2

# patching steamvr (without it, steamvr might lag to hell)
../patch_bindings_spam.sh "$HOME/.steam/steam/steamapps/common/SteamVR"

cleanup_alvr
cd ..

STEP_INDEX=6
sleep 2

# post messages
echog "From that point on, ALVR should be installed and WlxOverlay should be working. Please refer to https://github.com/galister/WlxOverlay/wiki/Getting-Started to familiarise with controls."
echor "To start alvr now you need to use start-alvr.sh script from this repository. It will also open Steam for you."
echog "In case you want to enter into container, use './open-container.sh' in terminal"
echog "Don't forget to enable Steam Play for all supported titles with latest (non-experimental) proton to make all games visible as playable in Steam."
echog "Thank you for using the script! Continue with installing alvr apk to headset and with very important Post-installation notes to configure ALVR and SteamVR"
