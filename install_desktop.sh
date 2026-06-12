#!/usr/bin/env bash

description="Install desktop environment on debian sid"
# author: Choops <choopsbd@gmail.com>

set -e

scriptpath="$(dirname "$(realpath "$0")")"

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

renew_sources() {
    rm -f /etc/apt/sources.list

    echo "Types: deb
URIs: http://deb.debian.org/debian
Suites: sid
Components: main contrib non-free non-free-firmware
Architectures: amd64 i386
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" \
        > /etc/apt/sources.list.d/sid.sources
}

install_desktop() {
    local my_de = $1

    renew_sources
    apt update -y
    apt install -y \
        task-desktop task-"$my_de"-desktop firefox needrestart apt-listbugs
    (dpkg -l | grep -q " firefox-esr") && apt purge -y firefox-esr
    apt autoremove --purge -y
}

set_config() {
    local user="$1"

    if ! (groups "${user}" | grep -q sudo); then
        gosudo_title="Privileges elevation"
        gosudo_text="Add user '$user' to 'sudo' group ?"
        if (whiptail --title "$gosudo_title" --yesno "$gosudo_text" 8 78); then
            adduser $user sudo
        fi
    fi

    rm -f /home/$user/.{profile,bashrc,vimrc}
    cp -f $scriptpath/dotfiles/profile /home/$user/.profile
    mkdir -p /home/$user/.vim
    cp -f $scriptpath/dotfiles/vimrc /home/$user/.vim/
    mkdir -p /home/$user/.config/bash
    cp -f $scriptpath/dotfiles/config/bash/* /home/$user/.config/bash/

    chown -R $user:$user /home/$user
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

for home_folder in /home/*; do
    user="$(basename "$home_folder")"
    (grep -q "^$user:" /etc/password) && set_config "$user"
done

