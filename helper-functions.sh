#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

STEAMVR_PROCESSES=(vrdashboard vrcompositor vrserver vrmonitor vrwebhelper vrstartup)

function echog() {
   echo -e "${RED}${STEP_INDEX}${NC} : ${GREEN}$1${NC}"
   sleep 0.5
}
function echor() {
   echo -e "${RED}${STEP_INDEX}${NC} : ${RED}$1${NC}"
   sleep 0.5
}
function cleanup_alvr() {
   echog "Cleaning up ALVR"
   for vrp in "${STEAMVR_PROCESSES[@]}"; do
      pkill -f $vrp
   done
   sleep 3
   for vrp in "${STEAMVR_PROCESSES[@]}"; do
      pkill -f -9 $vrp
   done
}

function wait_for_initial_steamvr() {
   for steamvr_process in vrmonitor vrserver; do
      until pidof "$steamvr_process" &>/dev/null; do
         sleep 1
      done
   done
}

function wait_for_full_steamvr() {
   for steamvr_process in "${STEAMVR_PROCESSES[@]}"; do
      until pidof "$steamvr_process" &>/dev/null; do
         sleep 1
      done
   done
}

function log_system() {
   cat /etc/os-release
}

function detect_gpu_count() {
   lspci | grep -ic vga
}

function detect_gpu() {
   local gpu
   gpu=$(lspci | grep -i vga | tr '[:upper:]' '[:lower:]')
   if [[ $gpu == *"amd"* ]]; then
      echo 'amd'
   elif [[ $gpu == *"nvidia"* ]]; then
      echo 'nvidia'
   elif [[ $gpu == *"intel"* ]]; then
      echo 'intel'
   else
      echo 'unknown'
   fi
}

function detect_audio() {
   if [[ -n "$(pgrep pipewire)" ]]; then
      echo 'pipewire'
   elif [[ -n "$(pgrep pulseaudio)" ]]; then
      echo 'pulse'
   else
      echo 'unknown'
   fi
}

function sanity_check_for_container() {
   if [ "$(distrobox list | grep -c $container_name)" -ne 1 ]; then
      echo 1
   fi
   echo 0
}

function write_json() {
   local field=$1
   local value=$2
   local path=$3

   if [ ! -e "$path" ]; then
      jq -n '{}' >"$path"
   fi

   jq --arg "$field" "$value" '. +=$ARGS.named' "$path" >"$path.tmp"

   mv "$path.tmp" "$path"
}

function read_json_field() {
   local field=$1
   local path=$2
   jq -r ".$field" "$path"
}