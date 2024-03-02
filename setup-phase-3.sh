#!/bin/bash

source ./env.sh
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

sudo pacman -q --noprogressbar -Syu jq --noconfirm || exit 1

GPU=$(jq -r '.gpu' <specs.json || exit 1)

if [[ "$GPU" != "nvidia" ]] && [[ "$GPU" != "amd" ]] && [[ "$GPU" != "intel" ]]; then
   echor "Something has gone wrong with specs GPU reading, aborting install"
   exit 1
fi
GPU=$(jq -r '.audio' <specs.json)
if [[ "$AUDIO_SYSTEM" != "pipewire" ]] && [[ "$GPU" != "pulse" ]]; then
   echor "Something has gone wrong with specs AUDIO_SYSTEM reading, aborting install"
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
sudo pacman-key --init || exit 1
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf
echo "LC_ALL=en_US.UTF-8" | sudo tee /etc/locale.conf
echo "export LANG=en_US.UTF-8 #alvr-distrobox" | tee -a ~/.bashrc
echo "export LC_ALL=en_US.UTF-8 #alvr-distrobox" | tee -a ~/.bashrc
sudo pacman -q --noprogressbar -Syu glibc lib32-glibc xdg-utils qt5-tools qt5-multimedia at-spi2-core lib32-at-spi2-core tar wget --noconfirm || exit 1

cd ..

exit 0
