#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

prefix="installation"
container_name="arch-alvr"

if [ "$EUID" -eq 0 ]; then
   echo "Please don't run this script as root (no sudo)."
   exit 1
fi
export DBX_CONTAINER_MANAGER=lilipod

source ./helper-functions.sh
source ./links.sh
init_prefixed_installation "$@"
source ./setup-dev-env.sh "$prefix"

distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic --env LANG=en_US.UTF-8 --env LC_ALL=en_US.UTF-8" -- $prefix/WlxOverlay.AppImage
