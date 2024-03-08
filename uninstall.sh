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
lilipod rm "$container_name"
lilipod rmi "$container_name"
rm "$prefix/bin/lilipod"

echog "Script will ask for sudo because it needs to remove container libpod files that can't be remove without superuser access"
DBX_SUDO_PROGRAM="$ROOT_PERMS_COMMAND" distrobox rm --rm-home "$container_name" --force

cd $prefix/distrobox-$distrobox_version*
./uninstall --prefix "$prefix"

echor "Be careful, superuser access requesting for deletion!"
echor "Confirm deletion of $prefix folder? (y/n)"
read -r CONFIRM_DELETE
if [ "$CONFIRM_DELETE" = "y" ] || [ "$CONFIRM_DELETE" = "Y" ]; then
   "$ROOT_PERMS_COMMAND" rm -rf "$prefix"
else
   echor "Did not delete $prefix folder"
fi

echog "Uninstall completed."
