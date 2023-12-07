#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

source ./helper-functions.sh

prefix="installation"
container_name="arch-alvr"


if [ "$EUID" -eq 0 ]; then
   echo "Please don't run this script as root (no sudo)."
   exit 1
fi
export DBX_CONTAINER_MANAGER=lilipod

init_prefixed_installation "$@"
source ./setup-dev-env.sh "$prefix"

ROOT_PERMS_COMMAND="sudo"
if ! command -v sudo &>/dev/null; then
   echog "Could not detect sudo, please write it as-is now and then press enter to confirm deletion of $prefix folder with $container_name container."
   read -r ROOT_PERMS_COMMAND
fi
podman stop "$container_name" 2>/dev/null

echo "Script now will ask for sudo because it needs to remove container files that can't be remove normally"
distrobox_lilipod_install_string=$(head <"$prefix/specs.conf" -3 | tail -1)
"$ROOT_PERMS_COMMAND" rm -rf "$prefix"
DBX_SUDO_PROGRAM="$ROOT_PERMS_COMMAND" distrobox-rm --rm-home "$container_name" 2>/dev/null

system_lilipod_install=$(echo "$distrobox_lilipod_install_string" | cut -d':' -f1 | cut -d'-' -f2)
if [[ "$system_lilipod_install" == "0" ]]; then
   lilipod rm --all
   lilipod rmi --all
   rm "$HOME/.local/bin/lilipod"
fi
system_distrobox_install=$(echo "$distrobox_lilipod_install_string" | cut -d':' -f2 | cut -d'-' -f2)
if [[ "$system_distrobox_install" == "0" ]]; then
   curl -s https://raw.githubusercontent.com/89luca89/distrobox/1.6.0.1/uninstall | sh
fi

echog "Uninstall completed."
