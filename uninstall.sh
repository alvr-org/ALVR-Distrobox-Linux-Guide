#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

source ./helper-functions.sh

prefix="installation"
container_name="arch-alvr"

init_prefixed_installation "$@"
source ./setup-dev-env.sh "$prefix"

echog "If you're using sudo, press enter, otherwise please write it as-is now and then press enter to confirm deletion of $prefix folder with $container_name container."
read -r ROOT_PERMS_COMMAND
if [[ -z "$ROOT_PERMS_COMMAND" ]]; then
   ROOT_PERMS_COMMAND="sudo"
fi

podman stop "$container_name" 2>/dev/null

distrobox_podman_install_string=$(head <"$prefix/specs.conf" -3 | tail -1)
"$ROOT_PERMS_COMMAND" rm -rf "$prefix"
DBX_SUDO_PROGRAM="$ROOT_PERMS_COMMAND" distrobox-rm --rm-home "$container_name" 2>/dev/null

system_podman_install=$(echo "$distrobox_podman_install_string" | cut -d':' -f1 | cut -d'-' -f2)
if [[ "$system_podman_install" == "0" ]]; then
   podman system reset
   rm "$HOME/.local/bin/podman"
fi 
system_distrobox_install=$(echo "$distrobox_podman_install_string" | cut -d':' -f2 | cut -d'-' -f2)
if [[ "$system_distrobox_install" == "0" ]]; then
   curl -s https://raw.githubusercontent.com/89luca89/distrobox/1.6.0.1/uninstall | sh
fi

echog "Uninstall completed."
