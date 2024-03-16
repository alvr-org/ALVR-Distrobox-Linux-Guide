#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

if [ "$EUID" -eq 0 ]; then
   echo "Please don't run this script as root (no sudo)."
   exit 1
fi

source ./env.sh
source ./helper-functions.sh
source ./setup-env.sh

if [ "$(sanity_check_for_container)" -eq 1 ]; then
   echor "There is more or less than 1 alvr container, something has gone wrong."
   echor "Please report setup.log and list bellow to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues"
   distrobox list
   exit 1
fi

distrobox enter --name "$container_name" --additional-flags "--env PATH=$prefix/$container_name/alvr_streamer_linux/usr/bin:$PATH --env XDG_CURRENT_DESKTOP=X-Generic --env LANG=en_US.UTF-8 --env LC_ALL=en_US.UTF-8"
