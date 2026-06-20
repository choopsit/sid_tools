#!/usr/bin/env bash

description="Install desktop environment on debian sid"
# author: Choops <choopsbd@gmail.com>

set -e

DEF="\e[0m"
RED="\e[31m"
CYN="\e[36m"

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

set_config() {
    local user="$1"
    local my_de="$2"

    if ! (groups "$user" | grep -q sudo); then
        gosudo="Add user '$user' to 'sudo' group ?"
        if (whiptail --yesno "$gosudo" 8 78); then
            adduser "$user" sudo
        fi
    fi

    echo -e "${CYN}'$user' profile configuration$DEF:"

    for dotfile in "profile" "bashrc" "vimrc"; do
        rm -f "/home/$user/.$dotfile"
    done

    cp -f "$scriptpath/dotfiles/profile" "/home/$user/.profile"

    mkdir -p "/home/$user/.config/bash"
    cp -f "$scriptpath/dotfiles/config/bash"/* "/home/$user/.config/bash"/

    if [[ $my_de == "xfce" ]]; then
        my_confs=("xfce4" "Thunar" "plank")
        for my_conf in ${myconfs[@]}; do
            mkdir -p "/home/$user/.config/$my_conf"
            cp -rf "$scriptpath/dotfiles/config/$my_conf"/* "/home/$user/.config/$my_conf"/
        done
    fi

    mkdir -p "/home/$user/.vim"
    cp -f "$scriptpath/dotfiles/vim/vimrc" "/home/$user/.vim"/

    chown -R "$user":"$user" "/home/$user"

    vimplug_url="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    vimplug_dest="/home/$user/.vim/autoload/plug.vim"
    su "$user" -c "mkdir -p $(dirname "$vimplug_dest")"
    su "$user" -c "curl -fLo $vimplug_dest --create-dirs $vimplug_url"
    su "$user" -c "vim +PlugInstall +qall"
}

install_desktop() {
    local my_de="$1"

    rm -f /etc/apt/sources.list
    cp -f "$scriptpath/conf/apt/sid.sources" /etc/apt/sources.list.d/
    dpkg --add-architecture i386

    echo -e "\n${CYN}System upgrade$DEF:"
    apt update -y
    apt upgrade -y

    echo -e "\n${CYN}Desktop environment installation$DEF:"
    apt install -y \
        linux-headers-amd64 build-essential \
        needrestart apt-listbugs \
        vim git curl rsync tree nfs-common \
        task-desktop task-"$my_de"-desktop \
        papirus-icon-theme breeze-cursor-theme libreoffice-style-sifr \
        firefox gimp steam-installer \
        ttf-mscorefonts-installer

    if [[ $my_de == "xfce" ]]; then
        apt install -y \
            arc-theme slick-greeter \
            redshift-gtk plank clapper

        apt purge xterm vim-tiny parole

        cp -f "$scriptpath/conf/lightdm/10_my.conf" /usr/share/lightdm/lightdm.conf.d/
    fi

    (dpkg -l | grep -q "firefox-esr") && apt purge -y firefox-esr

    echo -e "${CYN}System cleanup$DEF:"
    apt autoremove --purge -y

    "$scriptpath"/deploy_systools.sh

    for home_folder in /home/*; do
        my_user="$(basename "$home_folder")"
        (grep -q "^$my_user:" /etc/passwd) && set_config "$my_user" "$my_desktop"
    done
}

[[ $2 ]] && echo -e "${RED}ERR$DEF: Too many arguments" && usage 1

if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 ]]; then
    echo -e "${RED}ERR$DEF: Bad argument" && usage 1
fi

if [[ $(whoami) != root ]]; then
    echo -e "${RED}ERR$DEF: Need higher privileges"
    exit 1
fi

if ! (grep -q "sid" /etc/os-release); then
    echo -e "${RED}ERR$DEF: $(basename "$0") works only on Debian Sid"
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

if (whiptail --yesno "Reboot and enjoy ?" 8 78); then
    reboot
else
    exit 0
fi

