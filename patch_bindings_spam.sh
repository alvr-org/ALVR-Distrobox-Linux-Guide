#!/bin/bash

echo "Latest known working version for patching: 1.27.5"

if [[ -z "$1" ]]; then
	echo 'Enter absolute path to SteamVR (for example, /home/user/.local/share/Steam/steamapps/common/SteamVR)'
	read STEAMVR_PATH
else
	STEAMVR_PATH="$1"
fi

PATH_TO_PATCHING_FILE="$STEAMVR_PATH/resources/webinterface/dashboard/vrwebui_shared.js"
if [[ ! -f $PATH_TO_PATCHING_FILE ]]; then
	echo "Couldn't find required file for patch, aborting"
	exit 1
fi

echo 'In case of failed patching, please re-validate SteamVR files to make sure they stay unchanged'

echo Deleting SteamVR html cache
rm -r ~/.cache/SteamVR

CHANGED_OUT=$(sed -i 's/m=n(1380),g=n(9809);/m=n(1380),g=n(9809),refresh_counter=0,refresh_counter_max=75;/g w /dev/stdout' $PATH_TO_PATCHING_FILE )
if [[ -z $CHANGED_OUT ]]; then
	echo "Couldn't patch, exiting"
	exit 1
else
	echo "patched 1"
fi
CHANGED_OUT=$(sed -i 's/case"action_bindings_reloaded":this.OnActionBindingsReloaded(n);break;/case"action_bindings_reloaded":if(refresh_counter%refresh_counter_max==0){this.OnActionBindingsReloaded(n);}refresh_counter++;break;/g w /dev/stdout' $PATH_TO_PATCHING_FILE)
if [[ -z $CHANGED_OUT ]]; then
	echo "Couldn't patch, exiting"
	exit 1
else
	echo "patched 2"
fi
CHANGED_OUT=$(sed -i 's/l=n(3568),c=n(1073);/l=n(3568),c=n(1073),refresh_counter_v2=0,refresh_counter_max_v2=75;/g w /dev/stdout' $PATH_TO_PATCHING_FILE)
if [[ -z $CHANGED_OUT ]]; then
	echo "Couldn't patch, exiting"
	exit 1
else
	echo "patched 3"
fi
CHANGED_OUT=$(sed -i 's/OnActionBindingsReloaded(){this.GetInputState()}/OnActionBindingsReloaded(){if(refresh_counter_v2%refresh_counter_max_v2==0){this.GetInputState();}refresh_counter_v2++;}/g w /dev/stdout' $PATH_TO_PATCHING_FILE)
if [[ -z $CHANGED_OUT ]]; then
	echo "Couldn't patch, exiting"
	exit 1
else
	echo "patched 4"
fi

echo Successfully patched web file.
