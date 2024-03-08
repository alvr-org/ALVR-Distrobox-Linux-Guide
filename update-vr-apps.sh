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
   echor "Couldn't find alvr container."
   echor "Please report setup.log and list bellow to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues"
   distrobox list
   exit 1
fi

echog "Updating arch container, alvr"
distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic" -- 'paru -q --noprogressbar -Sy archlinux-keyring --noconfirm'
distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic" -- 'paru -Q alvr'
ALVR_STABLE_OUT=$?
distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic" -- 'paru -Q alvr-git'
ALVR_NIGHTLY_OUT=$?
if [[ $IS_NIGHTLY -eq 1 ]]; then
   if [[ $ALVR_STABLE_OUT -eq 0 ]]; then
      distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic" \
         -- 'paru -Runs alvr --noconfirm'
   fi
   distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic" \
      -- 'paru -q --noprogressbar -Syu alvr-git --noconfirm'
else
   if [[ $ALVR_NIGHTLY_OUT -eq 0 ]]; then
      distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic" \
         -- 'paru -Runs alvr-git --noconfirm'
   fi
   distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic" \
      -- 'paru -q --noprogressbar -Syu alvr --noconfirm'
fi

echog "Downloading alvr apk"
rm "$prefix/alvr_client_android.apk"
if [[ $IS_NIGHTLY -eq 1 ]]; then
   wget -q --show-progress -P "$prefix"/ "$NIGHTLY_ALVR_APK_LINK" || echor "Could not download apk, please download it from $NIGHTLY_ALVR_APK_LINK manually."
else
   wget -q --show-progress -P "$prefix"/ "$ALVR_APK_LINK" || echor "Could not download apk, please download it from $ALVR_APK_LINK manually."
fi

echog "Reinstalling wlxoverlay"
rm "$prefix/$WLXOVERLAY_FILENAME"
wget -O "$prefix/$WLXOVERLAY_FILENAME" -q --show-progress "$WLXOVERLAY_LINK"
chmod +x "$prefix/$WLXOVERLAY_FILENAME"

echog "Update finished."
