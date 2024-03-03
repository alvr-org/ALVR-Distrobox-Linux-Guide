#!/bin/bash

DBX_CONTAINER_MANAGER=lilipod
IS_NIGHTLY=0

# Folder names
prefix="installation-lilipod"
container_name="arch-alvr"

# Links
ALVR_APK_LINK='https://github.com/alvr-org/ALVR/releases/download/v20.6.1/alvr_client_android.apk'
NIGHTLY_ALVR_APK_LINK='https://github.com/alvr-org/ALVR-nightly/releases/latest/download/alvr_client_android.apk'
ALVR_APK_NAME='alvr_client_android.apk'
WLXOVERLAY_LINK='https://github.com/galister/wlx-overlay-s/releases/download/v0.2.3-3/WlxOverlay-S-v0.2.3-3-x86_64.AppImage'
WLXOVERLAY_FILENAME='WlxOverlay-S.AppImage'