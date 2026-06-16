#!/usr/bin/env bash

description="Set puseaudio-plugin volume control step"
# author: Choops <choopsbd@gmail.com>

set -e

DEF="\e[0m"
RED="\e[31m"


usage() {
    errcode="$1"

    [[ $errcode == 0 ]] && echo "$description"
    echo "Usage:"
    echo "  $(basename "$0") [OPTION] <STEP>"
    echo "  with STEP the percentage to apply to volume control step between 1 and 20"
    echo "Options:"
    echo -e "  -h,--help: Print this help\n"

    exit "$errcode"
}


[[ $# != 1 ]] && echo -e "${RED}ERR$DEF: Need one and only one argument" && usage 1
[[ $1 =~ ^-(h|-help)$ ]] && usage 0

if [[ $1 -lt 1 ]] || [[ $1 -gt 20 ]]; then
    echo -e "${RED}ERR$DEF: Bad argument" && usage 1
fi

! (ps -C xfce4-panel >/dev/null) && echo -e "${RED}ERR$DEF: DE is not XFCE" && exit 1

pa_step="$1"
pulseplug="$(xfconf-query -c xfce4-panel -lv | awk '/pulseaudio/ {print $1}')"

xfconf-query -c xfce4-panel -p "$pulseplug"/volume-step --create -t int -s "$pa_step"

echo -e "Volume control step set to $pa_step%\n"

