#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

./setup-phase-1-2.sh "$@" 2>&1 | tee setup.log || true
cp setup.log /tmp/alvr-setup.log
sed < /tmp/alvr-setup.log $'s/\033[[][^A-Za-z]*m//g' > setup.log
