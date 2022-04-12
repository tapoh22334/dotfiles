#!/bin/bash

function _scrnsvr () {
    local jpg_dir=/mnt/d/materials/painting/antoni_tapies
    trap 'exit 0' SIGUSR1

    while true; do
        clear

        img=$(find "$jpg_dir" -type f | shuf -n1)
        jp2a --colors --color-depth=8 "$img"

        echo "[" "$img" "]" "Press any key to continue"
        sleep 10 &
        wait $!
    done
}

function screensaver () {
    _scrnsvr &
    _PID_SS=$!

    read -k1 -r -s

    kill -SIGUSR1 $_PID_SS >/dev/null 2>&1
    clear
}
