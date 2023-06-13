#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

prefix="installation"
container_name="fedora-37-alvr"

source ./helper-functions.sh
source ./links.sh
init_prefixed_installation "$@"
source ./setup-dev-env.sh "$prefix"

echog "Starting up Steam"
distrobox enter --name "$container_name" -- steam &>/dev/null &
echog "Starting up ALVR"
distrobox enter --name "$container_name" -- $prefix/alvr_dashboard # fixme: alvr_dashboard temporary workaround until alvr fix
