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
echog "Setting up repositories and locale packages"
sudo dnf install glibc-locale-source \
   glibc-langpack-en \
   https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
   --assumeyes \
   --quiet || exit 1
echog "Setting up locale"
echo "LANG=\"en_US.UTF-8\"" | sudo tee -a /etc/locale.conf || exit 1
cd ..

exit 0
