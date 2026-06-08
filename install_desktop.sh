#!/usr/bin/env bash

description="Install desktop environment on debian sid"
# author: Choops <choopsbd@gmail.com>

set -e

usage() {
    errcode="$1"

    [[ $errcode == 0 ]] && echo "$description"

    echo "Usage:"
    echo "  ./$(basename "$0") [OPTION]"
    echo "  WRN: Must be run as 'root' or using 'sudo'"
    echo "Options:"
    echo "  -h,--help: Print this help"
    echo
}

install_desktop() {
    if [[ $1 ]]; then
        apt update -y
        apt install -y task-desktop task-"$1"-desktop firefox
        (dpkg -l | grep -q " firefox ") || 
            (apt install -y firefox && apt purge -y firefox-esr)
        apt autoremove --purge -y
    fi
}

gen_checklist() {
    checklist=()

    for choice in $@; do
        if [[ $choice == "xfce" ]]; then
            checklist+=("$choice" "|" "ON")
        else
            checklist+=("$choice" "|" "OFF")
        fi
    done

    for elt in ${checklist[@]}; do
        echo "$elt"
    done
}

[[ $2 ]] && echo "ERR: Too many arguments" && usage 1

if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 ]]; then
    echo "ERR: Bad argument" && usage 1
fi

if [[ $(whoami) != root ]]; then
    echo "ERR: Need higher privileges"
    exit 1
fi

if ! (grep -q "sid" /etc/os-release); then
    echo "ERR: $(basename "$0") works only on Debian Sid"
    exit 1
fi

desktop_list=(
    "xfce"
    "gnome"
    "cinnamon"
    "kde"
)

desktop_checklist=$(gen_checklist ${desktop_list[@]})

my_desktop=($(whiptail --separate-output --radiolist "Desktop Environment" \
    $((${#desktop_list[@]}+8)) 40 ${#desktop_list[@]} \
        ${desktop_checklist[@]} 3>&1 1>&2 2>&3))

install_desktop "$my_desktop"

./deploy_systools.sh

