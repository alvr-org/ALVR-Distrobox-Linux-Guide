#!/usr/bin/python
import os
import subprocess
import time

use_headset_audio = True
use_headset_mic = True

temp_data_path = "/run/user/1000/alvr_audio"


def get_process_output(cmd: str):
    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    data, err = process.communicate()
    if process.returncode == 0:
        return data.decode('utf-8').strip()
    else:
        print(err.decode('utf-8'))
        exit(1)


def unlink_node(node_name: str):
    all_links = get_process_output("pw-link -l -I")
    node_links = get_node_links(all_links, node_name)
    for link in node_links:
        subprocess.Popen(f"pw-link -d {link}", shell=True)


def unlink_audio_record():
    print("Unlinking previous nodes from audio record")
    unlink_node("alsa_capture.vrserver")


def unlink_mic_playback():
    print("Unlinking previous nodes from mic playback")
    unlink_node("alsa_playback.vrserver")


def get_node_links(pw_output: str, node_name: str):
    links = []
    is_inside_links = False
    for line in pw_output.split('\n'):
        strip_line = line.strip()
        if is_inside_links and not ("|<-" in strip_line or "|->" in strip_line):
            is_inside_links = False
        if not is_inside_links and node_name in strip_line and not ("|<-" in strip_line or "|->" in strip_line):
            is_inside_links = True
        if is_inside_links and ("|<-" in strip_line or "|->" in strip_line):
            links.append(strip_line.split(' ')[0])
    return links


def unload_modules():
    print('Unloading audio, microphone sink & source')
    unlink_mic_playback()
    unlink_audio_record()
    subprocess.Popen(f'pw-cli destroy ALVR-AUDIO-Sink', shell=True)
    subprocess.Popen(f'pw-cli destroy ALVR-MIC-Source', shell=True)


def create_null_sink_with_name_and_class(name: str, class_name: str):
    return subprocess.Popen("pw-cli create-node adapter "
                            f"'{{ factory.name=support.null-audio-sink node.name={name} media.class={class_name} "
                            "object.linger=true audio.position=[FL FR] monitor.channel-volumes=true }}'",
                            shell=True)


def setup_mic():
    print('Creating microphone sink & source and linking alvr playback to it')
    # This source is required so that any app can use it as microphone
    create_null_sink_with_name_and_class("ALVR-MIC-Source", "Audio/Source/Virtual")

    unlink_mic_playback()

    print("Linking microphone playback to microphone source")
    subprocess.Popen("pw-link alsa_playback.vrserver:output_FL ALVR-MIC-Source:input_FL", shell=True)
    subprocess.Popen("pw-link alsa_playback.vrserver:output_FR ALVR-MIC-Source:input_FR", shell=True)

    print("Setting ALVR mic as default source")
    subprocess.Popen("pactl set-default-source ALVR-MIC-Source", shell=True)


def setup_audio():
    print("Setting up audio")
    create_null_sink_with_name_and_class("ALVR-AUDIO-Sink", "Audio/Sink")

    unlink_audio_record()

    print("Linking current nodes from to record")
    subprocess.Popen("pw-link ALVR-AUDIO-Sink:monitor_FL alsa_capture.vrserver:input_FL", shell=True)
    subprocess.Popen("pw-link ALVR-AUDIO-Sink:monitor_FR alsa_capture.vrserver:input_FR", shell=True)

    print("Setting ALVR audio as default sink")
    subprocess.Popen("pactl set-default-sink ALVR-AUDIO-Sink", shell=True)


def do_action(action_name: str):
    if action_name == 'connect':
        unload_modules()
        time.sleep(0.25)
        if use_headset_audio:
            setup_audio()
        time.sleep(0.25)
        if use_headset_mic:
            setup_mic()
        pass
    elif action_name == 'disconnect':
        unload_modules()
        pass
    else:
        print('Unknown action')
        pass


if __name__ == "__main__":
    action = os.environ.get('ACTION')
    do_action(action)
