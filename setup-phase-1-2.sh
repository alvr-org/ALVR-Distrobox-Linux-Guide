#!/bin/bash

source ./helper-functions.sh
source ./env.sh

function phase1_lilipod_distrobox_install() {
   echor "Phase 1"
   mkdir "$prefix"
   cd "$prefix" || {
      echor "Couldn't go into installation folder on phase 1, aborting."
      exit 1
   }

   if ! command -v getsubid &>/dev/null; then
      # Most likely for ubuntu 22.04, related https://github.com/89luca89/lilipod/issues/7
      echog "You don't seem to have getsubids command, i will use whipped one instead"
      echog "But considering this fact, things might not work correctly for your distribution"
      cp "../getsubids" "$prefix/bin"
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
   distrobox_version="1.6.0.1" # commit lock to not have sudden changes in behaviour
   curl -s https://raw.githubusercontent.com/89luca89/distrobox/"$distrobox_version"/install | sh -s -- --prefix "$prefix"

   cd ..
}

function phase2_distrobox_container_creation() {
   echor "Phase 2"
   GPU=$(detect_gpu)
   AUDIO_SYSTEM=$(detect_audio)

   # Sanity checks
   if [[ "$(which lilipod)" != "$prefix/bin/lilipod" ]]; then
      echor "Failed to install lilipod properly"
      exit 1
   fi
   if [[ "$(which distrobox)" != "$prefix/bin/distrobox" ]]; then
      echor "Failed to install distrobox properly"
      exit 1
   fi

   echo "$GPU" | tee "$prefix/specs.conf"
   if [[ "$GPU" == "amd" ]]; then
      distrobox create --pull --image docker.io/library/archlinux:latest \
         --name "$container_name" \
         --home "$prefix/$container_name"
      if [ $? -ne 0 ]; then
         echor "Couldn't create distrobox container, please report setup.log to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues."
         echor "GPU: $GPU; AUDIO SYSTEM: $AUDIO_SYSTEM"
         exit 1
      fi
   elif [[ "$GPU" == nvidia* ]]; then
      CUDA_LIBS="$(find /usr/lib* -iname "libcuda*.so*")"
      if [[ -z "$CUDA_LIBS" ]]; then
         echor "Couldn't find CUDA on host, please install it, reboot and try again, as it's required for NVENC encoder support."
         exit 1
      fi
      distrobox create --pull --image docker.io/library/archlinux:latest \
         --name "$container_name" \
         --home "$prefix/$container_name" \
         --nvidia
      if [ $? -ne 0 ]; then
         echor "Couldn't create distrobox container, please report setup.log to https://github.com/alvr-org/ALVR-Distrobox-Linux-Guide/issues."
         echor "GPU: $GPU; AUDIO SYSTEM: $AUDIO_SYSTEM"
         exit 1
      fi
   else
      echor "Intel is not supported yet."
      exit 1
   fi

   echo "$AUDIO_SYSTEM" | tee -a "$prefix/specs.conf"
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

# Sanity checks
if [ "$EUID" -eq 0 ]; then
   echo "Please don't run this script as root (no sudo)."
   exit 1
fi
if [[ -e "$prefix" ]]; then
   echor "You're trying to overwrite previous installation with new installation, please use uninstall.sh first"
   exit 1
fi
if [[ "$prefix" =~ \  ]]; then
   echor "File path to container can't contains spaces as SteamVR will fail to launch if path to it contains spaces."
   echor "Please clone or unpack repository into another directory that doesn't contain spaces."
   exit 1
fi
if [ "$(detect_gpu_count)" -ne 1 ]; then
   echor "Multi-gpu systems are not yet supported with this installation method."
   echor "Please either disable igpu completely in UEFI/BIOS"
   echor "Or proceed with system-wide installation (using appimage) instead - with optimus manager for Nvidia to use only Nvidia"
   exit 1
fi

# Prevent host steam to be used during install, forcefully kill it (on steamos produces output like it tries to kill host processes and fails, fixme?...)
pkill -f steam

source ./setup-env.sh

log_system
phase1_lilipod_distrobox_install
phase2_distrobox_container_creation
