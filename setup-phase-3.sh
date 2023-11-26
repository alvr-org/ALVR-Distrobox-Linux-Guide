#!/bin/bash

source ./links.sh
source ./helper-functions.sh

if [[ -z "$prefix" ]]; then
   echor "No prefix found inside distrobox, aborting"
   exit 1
fi

echor "Phase 3"

cd "$prefix" || {
   echor "Couldn't go into installation folder on phase 3, aborting."
   exit 1
}

# Sanity checks (TODO: sanity check for distrobox/podman installation as well?)
# Get current gpu (and version in case if it's nvidia from configuration)
GPU="$(head <specs.conf -1 | tail -2)"
if [[ "$GPU" == nvidia* ]]; then
   GPU=$(echo "$GPU" | cut -d' ' -f1)
fi
if [[ "$GPU" != "nvidia" ]] && [[ "$GPU" != "amd" ]]; then
   echor "Something has gone wrong with specs.conf GPU reading, aborting install"
   exit 1
fi
AUDIO_SYSTEM="$(head <specs.conf -2 | tail -1)"
if [[ "$AUDIO_SYSTEM" != "pipewire" ]] && [[ "$GPU" != "pulse" ]]; then
   echor "Something has gone wrong with specs.conf AUDIO_SYSTEM reading, aborting install"
   exit 1
fi

# Renaming xdg-open from container because it will run host applications (like steam) instead of internal ones
sudo mv /usr/local/bin/xdg-open /usr/local/bin/xdg-open2

# Setting up arch
echog "Setting up repositories"
echo "[multilib]" | sudo tee -a /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
echog "Setting up locales"
echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
sudo pacman-key --init
sudo pacman -q --noprogressbar -Syu glibc lib32-glibc xdg-utils qt5-tools --noconfirm
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf
echo "LC_ALL=en_US.UTF-8" | sudo tee /etc/locale.conf
echo "export LANG=en_US.UTF-8 #alvr-distrobox" | tee -a ~/.bashrc
echo "export LC_ALL=en_US.UTF-8 #alvr-distrobox" | tee -a ~/.bashrc

cd ..

exit 0
