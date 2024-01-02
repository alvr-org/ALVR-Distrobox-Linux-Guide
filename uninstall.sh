#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

if [ "$EUID" -eq 0 ]; then
   echo "Please don't run this script as root (no sudo)."
   exit 1
fi

source ./env.sh
source ./helper-functions.sh
source ./setup-env.sh

ROOT_PERMS_COMMAND="sudo"
if ! command -v sudo &>/dev/null; then
   echog "Could not detect sudo, please write sudo-like command as-is now and then press enter to continue."
   read -r ROOT_PERMS_COMMAND
fi

lilipod stop "$container_name" 2>/dev/null
echo "Script now will ask for sudo because it needs to remove container files that can't be remove normally"
DBX_SUDO_PROGRAM="$ROOT_PERMS_COMMAND" distrobox rm --rm-home "$container_name" --force

curl -s https://raw.githubusercontent.com/89luca89/distrobox/1.6.0.1/uninstall | sh -s -- --prefix "$prefix"

lilipod rm --all
lilipod rmi --all
rm "$prefix/bin/lilipod"

"$ROOT_PERMS_COMMAND" rm -rf "$prefix"

echog "Uninstall completed."
