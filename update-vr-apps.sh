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
(
   cd "$prefix" || exit 1
   rm "$ALVR_STREAMER_NAME"
   rm -r "$container_name/alvr_streamer_linux"
   if [[ $IS_NIGHTLY -eq 1 ]]; then
      wget -q --show-progress "$ALVR_NIGHTLY_STREAMER_LINK" || exit 1
   else
      wget -q --show-progress "$ALVR_STABLE_STREAMER_LINK" || exit 1
   fi
   chmod +x "$ALVR_STREAMER_NAME"
   ./"$ALVR_STREAMER_NAME" --appimage-extract
   mv squashfs-root "$container_name/alvr_streamer_linux" || exit 1
)
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
