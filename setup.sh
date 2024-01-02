#!/bin/bash
cd $(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

./setup-phase-1-2.sh "$@" 2>&1 | tee setup.log || true
cp setup.log /run/user/1000/alvr-setup.log
sed </run/user/1000/alvr-setup.log $'s/\033[[][^A-Za-z]*m//g' >setup.log
