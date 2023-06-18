#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

source ./helper-functions.sh

# Required on xorg setups
if [[ -z "$WAYLAND_DISPLAY" ]]; then
    xhost "+si:localuser:$USER"
    if [ $? -ne 0 ]; then
        echor "Couldn't use xhost, please install it and re-run installation"
        exit 1
    fi
fi

if [[ -n "$(which podman)" ]] && [[ -n "$(which distrobox)" ]]; then
    echog "Using system podman and distrobox"
    return
fi

init_prefixed_installation "$@"

export PATH="$HOME/.local/bin:$PATH"