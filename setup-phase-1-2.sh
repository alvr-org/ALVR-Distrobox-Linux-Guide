#!/bin/bash

source ./helper-functions.sh

prefix="installation"
container_name="arch-alvr"
system_podman_install=1
system_distrobox_install=1

function log_system() {
   cat /etc/os-release
}

function detect_gpu() {
   local gpu
   gpu=$(lspci | grep -i vga | tr '[:upper:]' '[:lower:]')
   if [[ $gpu == *"amd"* ]]; then
      echo 'amd'
      return
   elif [[ $gpu == *"nvidia"* ]]; then
      echo 'nvidia'
      return
   else
      echo 'intel'
      return
   fi
}

function detect_audio() {
   if [[ -n "$(pgrep pipewire)" ]]; then
      echo 'pipewire'
   elif [[ -n "$(pgrep pulseaudio)" ]]; then
      echo 'pulse'
   else
      echo 'none'
   fi
}

function phase1_podman_distrobox_install() {
   echor "Phase 1"
   mkdir "$prefix"
   cd "$prefix" || { 
      echor "Couldn't go into installation folder on phase 1, aborting." ; 
      exit 1 
   }

   if ! which podman; then
      system_podman_install=0
      echog "Installing static podman"
      wget -O podman https://github.com/89luca89/podman-launcher/releases/download/v0.0.3/podman-launcher-amd64 
      chmod +x podman
      mkdir -p "$HOME/.local/bin"
      mv podman "$HOME/.local/bin"
   fi

   if ! which distrobox; then
      echog "Installing distrobox"   
      system_distrobox_install=0
      distrobox_commit="1.5.0.2" # commit lock to not have sudden changes in behaviour

      git clone https://github.com/89luca89/distrobox.git distrobox
      cd distrobox || exit
      git checkout "$distrobox_commit"
      mkdir -p "$HOME/.local/bin"
      ./install
      cd ..
   fi
   cd ..
}

function phase2_distrobox_container_creation() {
   echor "Phase 2"
   GPU=$(detect_gpu)
   AUDIO_SYSTEM=$(detect_audio)

   source ./setup-dev-env.sh "$prefix"

   # Sanity checks
   if [[ "$system_podman_install" == 0 ]]; then
      if [[ "$(which podman)" != "$HOME/.local/bin/podman" ]]; then
         echor "Failed to install podman properly"
         exit 1
      fi
   fi
   if [[ "$system_distrobox_install" == 0 ]]; then
      if [[ "$(which distrobox)" != "$HOME/.local/bin/distrobox" ]]; then
         echor "Failed to install distrobox properly"
         exit 1
      fi
   fi
   
   echo "$GPU" | tee "$prefix/specs.conf"
   if [[ "$GPU" == "amd" ]]; then
      distrobox-create --pull --image docker.io/library/archlinux:latest \
         --name "$container_name" \
         --home "$PWD/$prefix/$container_name"
      if [ $? -ne 0 ]; then
         echor "Couldn't create distrobox container, please report it to maintainer."
         echor "GPU: $GPU; AUDIO SYSTEM: $AUDIO_SYSTEM"
         exit 1
      fi
   elif [[ "$GPU" == nvidia* ]]; then
      CUDA_LIBS="$(find /usr/lib* -iname "libcuda*.so*")"
      if [[ -z "$CUDA_LIBS" ]]; then
         echor "Couldn't find CUDA on host, please install it, reboot and try again, as it's required for NVENC encoder support."
         exit 1
      fi
      distrobox-create --pull --image docker.io/library/archlinux:latest \
         --name "$container_name" \
         --home "$PWD/$prefix/$container_name" \
         --nvidia
      if [ $? -ne 0 ]; then
         echor "Couldn't create distrobox container, please report it to maintainer."
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
      echor "Unsupported audio system ($AUDIO_SYSTEM). Please report this issue to maintainer."
      exit 1
   fi
   
   if [[ "$system_podman_install" == 0 ]] || [[ "$system_distrobox_install" == 0 ]]; then
      echo "podman-$system_podman_install:distrobox-$system_distrobox_install" | tee -a "$prefix/specs.conf"
   fi

   distrobox-enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic --env prefix='$prefix' --env container_name='$container_name'" -- ./setup-phase-3.sh
   if [ $? -ne 0 ]; then
      echor "Couldn't install distrobox container first time at phase 3, please report it as an issue with attached setup.log from the directory."
      # envs are required! otherwise first time install won't have those env vars, despite them being even in bashrc, locale conf, profiles, etc
      exit 1
   fi
   distrobox-stop --name "$container_name" --yes
   distrobox-enter --name "$container_name" --additional-flags "--env XDG_CURRENT_DESKTOP=X-Generic --env prefix='$prefix' --env container_name='$container_name'" -- ./setup-phase-4.sh
   if [ $? -ne 0 ]; then
      echor "Couldn't install distrobox container first time at phase 4, please report it as an issue with attached setup.log from the directory."
      # envs are required! otherwise first time install won't have those env vars, despite them being even in bashrc, locale conf, profiles, etc
      exit 1
   fi
}

init_prefixed_installation "$@"

# Sanity checks
if [[ "$prefix" =~ \  ]]; then
   echor "File path to container can't contains spaces as SteamVR will fail to launch if path to it contains spaces."
   echor "Please clone or unpack repository into another directory that doesn't contain spaces."
   exit 1
fi
if [[ -e "$prefix" ]]; then
   echor "You're trying to overwrite previous installation with new installation, please use uninstall.sh first"
   exit 1
fi
# Prevent host steam to be used during install, forcefully kill it (on steamos produces output like it tries to kill host processes and fails, fixme?...)
pkill -f steam

log_system
phase1_podman_distrobox_install
phase2_distrobox_container_creation
