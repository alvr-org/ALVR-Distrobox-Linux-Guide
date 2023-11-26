#!/bin/bash

source ./links.sh
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
if [[ "$WAYLAND_DISPLAY" != "" ]]; then
   echog "And after installing, please put: WAYLAND_DISPLAY='' %command%"
   echog "into SteamVR commandline options."
fi

# Define proper steam desktop file
mkdir ~/.config
xdg-mime default steam.desktop x-scheme-handler/steam

xdg-open steam://install/250820 &>/dev/null &
echog "Enabling ctrl+c prevention."
trap 'echog "Oops you have pressed ctrl+c which would have stopped this setup, dont worry, i prevented it from doing that"' 2
echog "Wait for SteamVR installation and press enter here"
read
echog "Copy (ctrl + shift + c from terminal) and launch command bellow from your host terminal shell (outside this shell, container) and press enter to continue there. This prevents annoying popup (yes/no with asking for superuser) that prevents steamvr from launching automatically."
echog "sudo setcap CAP_SYS_NICE+ep '$HOME/.steam/steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher'"
echog "After you execute that command on host, press enter to continue."
read
echog "Disabling ctrl+c prevention, be careful."
trap 2
echog "Running steam once to generate startup files."
steam -vgui steam://run/250820 &>/dev/null &
wait_for_initial_steamvr
cleanup_alvr
echog "At this point you can safely add your external library from the host system ('/home/$USER' is same from inside the script container as from outside)"
echog "When ready for next step, press enter to continue."
read

export STEP_INDEX=3
sleep 2

echog "Installing alvr"
echog "This installation script will download apk client for the headset later, but you shouldn't connect it to alvr during this script installation, leave it to post install."
paru -q --noprogressbar -S rust alvr-git --noconfirm --assume-installed vulkan-driver --assume-installed lib32-vulkan-driver || exit 1
echog "ALVR and dashboard now launch and when it does that, skip setup (X button on right up corner)."
echog "After that, launch SteamVR using button on left lower corner and after starting steamvr, you should see one headset showing up in steamvr menu and 'Streamer: Connected' in ALVR dashboard."
echog "In ALVR Dashboard settings at left side, at the top set 'Game Audio' and 'Game Microphone' to pipewire (if possible)."
echog "Find 'On connect script' and 'On disconnect script' as well and put $(realpath "$PWD"/../audio-setup.sh) (confirm each of them with enter on text box) into both of them. This is for automatic microphone that will load/unload based on connection to the headset"
echog "Tick 'Open setup wizard' too to prevent popup on dashboard startup."
echor "After you have done with this, press enter here, and don't close alvr dashboard manually."
alvr_dashboard &>/dev/null &
read
echog "Downloading ALVR apk, you can install it now from the $(realpath "$PWD")  folder into your headset using either ADB or Sidequest on host."
wget -q --show-progress "$ALVR_APK_LINK"
echog "Don't close ALVR."

STEP_INDEX=4
sleep 2

# installing wlxoverlay
echog "For Desktop usability, we will install WlxOverlay, it works on Wayland and has ability to control whole desktop from inside VR."
wget -q --show-progress -O "$WLXOVERLAY_FILENAME" "$WLXOVERLAY_LINK"
chmod +x "$WLXOVERLAY_FILENAME"
if [[ "$WAYLAND_DISPLAY" != "" ]]; then
   echog "If you're not (on wlroots-based compositor like Sway), it will ask for display to choose. Choose the one display that contains every other (usually first in list)."
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

# patching steamvr (without it, steamvr might lag to hell )
../patch_bindings_spam.sh "$HOME/.steam/steam/steamapps/common/SteamVR"

cleanup_alvr
cd ..

STEP_INDEX=6
sleep 2

# post messages
echog "From that point on, ALVR should be installed and WlxOverlay should be working. Please refer to https://github.com/galister/WlxOverlay/wiki/Getting-Started to familiarise with controls."
echor "To start alvr now you need to use start-alvr.sh script from this repository. It will also open Steam for you."
echog "In case you want to enter into container, write 'source setup-env.sh && distrobox-enter $container_name' in console"
echog "Don't forget to enable Steam Play for all supported titles with latest (non-experimental) proton to make all games visible as playable in Steam."
echog "To start WlxOverlay for using desktop in vr , open start-overlay.sh script."
echog "Thank you for using the script! Continue with installing alvr apk to headset and with very important Post-installation notes to configure ALVR and SteamVR"
