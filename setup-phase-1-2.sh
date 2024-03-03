#!/bin/bash

source ./env.sh
source ./helper-functions.sh
source ./setup-env.sh

function phase1_lilipod_distrobox_install() {
   echor "Phase 1"
   cd "$prefix" || {
      echor "Couldn't go into installation folder on phase 1, aborting."
      exit 1
   }

   if ! command -v getsubids &>/dev/null; then
      # Most likely for ubuntu 22.04 and older distros, related https://github.com/89luca89/lilipod/issues/7
      echog "You don't seem to have getsubids command, i will use whipped one instead"
      echog "But considering this fact, things might not work correctly for your distribution"
      cp "../getsubids" "$prefix/bin/"
   else
      if ! getsubids -g "$(whoami)"; then
         echor "Couldn't verify getsubids command, do you have updated getsubid/shadow package?"
         exit 1
      fi
   fi

   echog "Installing lilipod"
   wget -O lilipod https://github.com/89luca89/lilipod/releases/download/v0.0.1/lilipod-linux-amd64
   chmod +x lilipod
   mkdir -p "$prefix/bin"
   mv lilipod "$prefix/bin"

   echog "Installing distrobox"
   distrobox_version="1.7.0" # commit lock to not have sudden changes in behaviour
   curl -s https://raw.githubusercontent.com/89luca89/distrobox/"$distrobox_version"/install | sh -s -- --prefix "$prefix"

   cd ..
}

function phase2_distrobox_container_creation() {
   echor "Phase 2"
   GPU=$(detect_gpu)
   AUDIO_SYSTEM=$(detect_audio)

   # Sanity checks for phase 1
   if [[ "$(which lilipod)" != "$prefix/bin/lilipod" ]]; then
      echor "Failed to install lilipod properly"
      exit 1
   fi
   if [[ "$(which distrobox)" != "$prefix/bin/distrobox" ]]; then
      echor "Failed to install distrobox properly"
      exit 1
   fi

   write_json gpu "$GPU" "$prefix/specs.json"
   if [[ "$GPU" == "amd" ]] || [[ "$GPU" == "intel" ]]; then
      distrobox create --pull --image docker.io/archlinux/archlinux:latest \
         --name "$container_name" \
         --home "$prefix/$container_name"
   elif [[ "$GPU" == nvidia* ]]; then
      CUDA_LIBS="$(find /usr/lib* -iname "libcuda*.so*")"
      if [[ -z "$CUDA_LIBS" ]]; then
         echor "Couldn't find CUDA on host, please install it, reboot and try again, as it's required for NVENC encoder support."
         exit 1
      fi
      distrobox create --pull --image docker.io/archlinux/archlinux:latest \
         --name "$container_name" \
         --home "$prefix/$container_name" \
         --nvidia
   else
      echor "Unsupported gpu found, can't proceed. Please report setup.log to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues."
      exit 1
   fi
   if [ $? -ne 0 ]; then
      echor "Couldn't create distrobox container, please report setup.log to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues."
      echor "GPU: $GPU; AUDIO SYSTEM: $AUDIO_SYSTEM"
      exit 1
   fi

   write_json audio "$AUDIO_SYSTEM" "$prefix/specs.json"
   if [[ "$AUDIO_SYSTEM" == "pulse" ]]; then
      echor "Do note that pulseaudio won't work with automatic microphone routing as it requires pipewire."
   elif [[ "$AUDIO_SYSTEM" != "pipewire" ]]; then
      echor "Unsupported audio system ($AUDIO_SYSTEM). please report setup.log to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues."
      exit 1
   fi

   distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic --env prefix='$prefix' --env container_name='$container_name'" -- ./setup-phase-3.sh
   if [ $? -ne 0 ]; then
      echor "Couldn't install distrobox container first time at phase 3, please report setup.log to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues."
      # envs are required! otherwise first time install won't have those env vars, despite them being even in bashrc, locale conf, profiles, etc
      exit 1
   fi
   distrobox stop "$container_name" --yes
   distrobox enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic --env prefix='$prefix' --env container_name='$container_name'" -- ./setup-phase-4.sh
   if [ $? -ne 0 ]; then
      echor "Couldn't install distrobox container first time at phase 4, please report setup.log to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues."
      # envs are required! otherwise first time install won't have those env vars, despite them being even in bashrc, locale conf, profiles, etc
      exit 1
   fi
}

function sanity_checks() {
   if [ "$EUID" -eq 0 ]; then
      echo "Please don't run this script as root (no sudo)."
      exit 1
   fi
   if [[ -e "$prefix/arch-alvr" ]]; then
      echor "You're trying to overwrite previous installation with new installation, please use uninstall.sh first"
      exit 1
   fi
   if [[ "$prefix" =~ \  ]]; then
      echor "File path to container can't contains spaces as SteamVR will fail to launch if path to it contains spaces."
      echor "Please clone or unpack repository into another directory that doesn't contain spaces."
      exit 1
   fi
   if [ "$(detect_gpu_count)" -ne 1 ]; then
      echog "Multi-gpu systems might not work with this installation, but script will still continue and attempt to work."
      echog "For this to work on INTEL + NVIDIA setup you must use 'prime-run %command%' (without quotes) on each game commandline parameters in Steam."
      echor "Please confirm that you have read line above and know what to do (y/N)"
      read -r CONFIRM
      if [[ $CONFIRM != "y" ]] && [[ $CONFIRM != "Y" ]]; then
         echor "User has not acknowledged notice, exiting."
         exit 1
      fi
      write_json multi_gpu 1 "$prefix/specs.json"
   else
      write_json multi_gpu 0 "$prefix/specs.json"
   fi
   disk_space=$(df -Pk . | sed 1d | grep -v used | awk '{ print $4 "\t" }')
   disk_space=$((10#${disk_space} / 1024 / 1024))
   write_json disk_space "$disk_space" "$prefix/specs.json"
   if ((disk_space < 15)); then
      echor "Installation might require up to least 15 gb during installation (steamvr + alvr build)."
      echor "You have less than 15 gb of free space available, please free up space for installation."
      exit 1
   fi
}

function install_jq() {
   # Install jq to local PATH for script
   mkdir -p "$prefix/bin"
   wget -q --show-progress -O "$prefix/bin/jq" https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
}

install_jq
sanity_checks

# Prevent host steam to be used during install, forcefully kill it (on steamos produces output like it tries to kill host processes and fails, fixme?...)
pkill -f steam

log_system
phase1_lilipod_distrobox_install
phase2_distrobox_container_creation
