#!/usr/bin/env bash

description="Line-in listening management"
# author: Choops <choopsbd@gmail.com>

set -e

DEF="\e[0m"
RED="\e[31m"


usage() {
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo "$description"
    echo "Usage:"
    echo "  $(basename "$0") [OPTION] <OPTION>"
    echo "Options:"
    echo "  on:        Start listening to line-in"
    echo "  off:       Stop listening to line-in"
    echo -e "  -h,--help: Print this help\n"

    exit "${errcode}"
}


[[ $# != 1 ]] && echo -e "${RED}ERR$DEF: Need one and only one argument" && usage 1

if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 = on ]]; then
    pactl load-module module-loopback latency_msec=1
elif [[ $1 = off ]]; then
    pactl unload-module module-loopback
elif [[ $1 ]]; then
    echo "${RED}ERR$DEF: Bad argument"
fi

