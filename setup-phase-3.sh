#!/bin/bash

source ./links.sh
source ./helper-functions.sh

if [[ -z "$prefix" ]]; then
   echor "No prefix found inside distrobox, aborting"
   exit 1
fi

echor "Phase 3"

cd "$prefix" || echor "Couldn't go into installation folder, aborting."

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
if [[ "$AUDIO_SYSTEM" != "pipewire" ]] || [[ "$GPU" != "pulse" ]]; then
   echor "Something has gone wrong with specs.conf AUDIO_SYSTEM reading, aborting install"
   exit 1
fi

# Setting up fedora 38
echog "Setting up locales and repositories"
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf || exit 1
echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/locale.conf || exit 1
echo "export LANG=en_US.UTF-8 #alvr-distrobox" | tee -a ~/.bashrc || exit 1
echo "export LC_ALL=en_US.UTF-8 #alvr-distrobox" | tee -a ~/.bashrc || exit 1
sudo ln -sf /run/host/etc/localtime /etc/localtime || echor Setting timezone failed, symlink it manually inside container
sudo dnf install glibc-locale-source \
   glibc-langpack-en \
   https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
   --assumeyes || exit 1

cd ..

exit 0
