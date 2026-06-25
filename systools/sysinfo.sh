#!/usr/bin/env bash

description="Get essential system info and optionally proceed a system upgrade"
# author: Choops <choopsbd@gmail.com>

#set -e

DEF="\e[0m"
RED="\e[31m"
CYN="\e[36m"

scriptpath="$(dirname "$(realpath "$0")")"


usage() {
    errcode="$1"

    [[ $errcode == 0 ]] && echo "$description"

    echo "Usage:"
    echo "  ./$(basename "$0") [OPTION]"
    echo "Options:"
    echo "  -u,--update: Proceed a system upgrade before showing info (need sudo)"
    echo -e "  -h,--help:   Print this help\n"
    echo
}


[[ $2 ]] && echo "${RED}ERR$DEF: Too many arguments" && usage 1

if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 =~ ^-(u|-update)$ ]]; then
    colloid_gtk_folder=/usr/share/themes/Colloid-Dark-Gruvbox
    gruvbox_icons_folder=/usr/share/icons/Gruvbox-Plus-Dark
    if { [[ -d "$colloid_gtk_folder" ]] || [[ -d "$gruvbox_icons_folder" ]];} then
        echo -e "${CYN}Themes upgrade$DEF:"
        [[ -d "$colloid_gtk_folder" ]] && colloid_gtk
        [[ -d "$gruvbox_icons_folder" ]] && gruvbox_icons
    fi
    echo -e "${CYN}Sources update$DEF:"
    sudo apt update
    echo -e "\n${CYN}System upgrade$DEF:"
    sudo apt full-upgrade
    echo -e "\n${CYN}System cleanup$DEF:"
    sudo apt autoremove --purge
    echo
elif [[ $1 ]]; then
    echo "${RED}ERR$DEF: Bad argument" && usage 1
fi

echo -e "${CYN}System Informations$DEF:"
date +"%a %d %b %Y - %R:%S"
echo
binfo
bdf

if [[ -d "$HOME/Projects/git" ]]; then
    echo -e "${CYN}Git repos status $DEF:"
    [[ -f /usr/local/bin/statgitrepos ]] && statgitrepos
fi

