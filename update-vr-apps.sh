#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

prefix="installation"

source ./links.sh
source ./helper-functions.sh

init_prefixed_installation "$@"
source ./setup-dev-env.sh "$prefix"

echog "Reinstalling alvr"
rm -r "${prefix:?}/alvr_dashboard" "${prefix:?}/${ALVR_APK_NAME:?}" # fixme: alvr_dashboard temporary workaround until alvr fix
wget -q --show-progress -P $prefix/ "$ALVR_LINK"
chmod +x "$prefix/$ALVR_FILENAME"
mv "$prefix/$ALVR_FILENAME" "$prefix/alvr_dashboard" # fixme: alvr_dashboard temporary workaround until alvr fix
echog "Downloading alvr apk"
wget -q --show-progress -P $prefix/ "$ALVR_APK_LINK"

echog "Reinstalling wlxoverlay"
rm "$prefix"/"$WLXOVERLAY_FILENAME"
wget -O "$prefix/$WLXOVERLAY_FILENAME" -q --show-progress "$WLXOVERLAY_LINK"
chmod +x "$prefix/$WLXOVERLAY_FILENAME"

echog "Installation finished."
