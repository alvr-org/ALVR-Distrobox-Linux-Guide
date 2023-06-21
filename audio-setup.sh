#!/bin/bash

function get_alvr_playback_source_id() {
  local last_node_name=''
  local last_node_id=''
  pactl list $1 | while read -r line; do
    node_id=$(echo "$line" | grep -oP "$2 #\K.+" | sed -e 's/^[ \t]*//')
    node_name=$(echo "$line" | grep -oP 'node.name = "\K[^"]+' | sed -e 's/^[ \t]*//')
    if [[ "$node_id" != '' ]] && [[ "$last_node_id" != "$node_id" ]]; then
      last_node_id="$node_id"
    fi
    if [[ -n "$node_name" ]] && [[ "$last_node_name" != "$node_name" ]]; then
      last_node_name="$node_name"
      if [[ "$last_node_name" == "$3" ]]; then
        echo "$last_node_id"
        return
      fi
    fi
  done
}

function get_sink_id() {
  local sink_name
  sink_name=$1
  pactl list short sinks | grep "$sink_name" | cut -d$'\t' -f1
}

function setup_mic() {
  echo "Creating microphone sink & source and linking alvr playback to it"
  # This sink is required so that it persistently auto-connects to alvr playback later
  pactl load-module module-null-sink sink_name=ALVR-MIC-Sink media.class=Audio/Sink
  # This source is required so that any app can use it as microphone
  pactl load-module module-null-sink sink_name=ALVR-MIC-Source media.class=Audio/Source/Virtual
  # We link them together
  pw-link ALVR-MIC-Sink ALVR-MIC-Source
  # And we assign playback of pipewire alsa playback to created alvr sink
  pactl move-sink-input "$(get_alvr_playback_source_id sink-inputs 'Sink Input' alsa_playback.vrserver)" "$(get_sink_id ALVR-MIC-Sink)"
}

function setup_audio() {
  echo "Setting up audio"
  pactl load-module module-null-sink sink_name=ALVR-AUDIO-Sink media.class=Audio/Sink
  pactl set-default-sink ALVR-AUDIO-Sink
  pactl move-source-output "$(get_alvr_playback_source_id source-outputs 'Source Output' alsa_capture.vrserver)" "$(get_sink_id ALVR-AUDIO-Sink)"
}

function unload_mic() {
  if pactl list short sinks | grep ALVR-MIC-Sink || pactl list short sources | grep ALVR-MIC-Source; then 
    echo "Unloading microphone sink & source"
    pw-link --disconnect ALVR-MIC-Sink ALVR-MIC-Source
    pw-cli destroy ALVR-MIC-Sink
    pw-cli destroy ALVR-MIC-Source
  else 
    echo Skipping unload, mic sinks are not present
  fi
}

function unload_sink() {
  if pactl list short sinks | grep ALVR-AUDIO-Sink; then 
    echo "Unloading audio sink"
    pw-cli destroy ALVR-AUDIO-Sink
  else
    echo Skipping unload, audio sink not present
  fi
}

case $ACTION in
connect)
  sleep 1.5
  unload_mic
  unload_sink
  setup_mic
  setup_audio
  ;;
disconnect)
  # Wait for cpal to destroy playbacks and for suspend timeout to be gone before destroying sinks
  sleep 1.5
  unload_mic
  unload_sink
  ;;
esac
