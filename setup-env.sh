#!/bin/bash

source ./env.sh
source ./helper-functions.sh

prefix="$(realpath "$prefix")"

# Required on xorg setups
if [[ -z "$WAYLAND_DISPLAY" ]]; then
    xhost "+si:localuser:$USER"
    if [ $? -ne 0 ]; then
        echor "Couldn't use xhost, please install it and re-run installation"
        exit 1
    fi
fi

export prefix
export PATH="$prefix/bin/:$PATH"