#!/bin/bash

source ./links.sh
source ./helper-functions.sh

if [[ -z "$prefix" ]]; then
   echor "No prefix found inside distrobox, aborting"
   exit 1
fi

echor "Phase 3"

cd "$prefix" || echor "Couldn't go into installation folder, aborting."

# Setting up fedora 38
echog "Setting up locales and repositories"
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf || exit 1
echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/locale.conf || exit 1
echo "export LANG=en_US.UTF-8 #alvr-distrobox" | tee -a ~/.bashrc || exit 1
echo "export LC_ALL=en_US.UTF-8 #alvr-distrobox" | tee -a ~/.bashrc || exit 1
sudo dnf install glibc-locale-source \
   glibc-langpack-en \
   https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
   --assumeyes || exit 1

cd ..

exit 0
