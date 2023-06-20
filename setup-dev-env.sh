#!/bin/bash

source ./helper-functions.sh

# Required on xorg setups
if [[ -z "$WAYLAND_DISPLAY" ]]; then
    xhost "+si:localuser:$USER"
    if [ $? -ne 0 ]; then
        echor "Couldn't use xhost, please install it and re-run installation"
        exit 1
    fi
fi

if which podman && which distrobox; then
    echog "Using system podman and distrobox"
    return
fi

export PATH="$HOME/.local/bin:$HOME/.local/podman/bin:$PATH"