#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

prefix="installation"
container_name="arch-alvr"

source ./links.sh
source ./helper-functions.sh

init_prefixed_installation "$@"
source ./setup-dev-env.sh "$prefix"

echog "Updating arch container, alvr"
distrobox-enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic --env prefix='$prefix' --env container_name='$container_name'" -- 'paru -q --noprogressbar -Sy archlinux-keyring --noconfirm && paru -q --noprogressbar -Syu --noconfirm'

echog "Downloading alvr apk"
rm "$prefix/alvr_client_android.apk"
wget -q --show-progress -P $prefix/ "$ALVR_APK_LINK"

echog "Reinstalling wlxoverlay"
rm "$prefix/$WLXOVERLAY_FILENAME"
wget -O "$prefix/$WLXOVERLAY_FILENAME" -q --show-progress "$WLXOVERLAY_LINK"
chmod +x "$prefix/$WLXOVERLAY_FILENAME"

echog "Update finished."
