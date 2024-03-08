#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

if [ "$EUID" -eq 0 ]; then
   echo "Please don't run this script as root (no sudo)."
   exit 1
fi

source ./env.sh
source ./helper-functions.sh
source ./setup-env.sh

if ! sanity_check_for_container; then
   echor "Couldn't find alvr container."
   echor "Please report setup.log and list bellow to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues"
   distrobox list
   exit 1
fi

echog "Starting WlxOverlay-S"
distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic --env LANG=en_US.UTF-8 --env LC_ALL=en_US.UTF-8" -- "$prefix"/"$WLXOVERLAY_FILENAME"
