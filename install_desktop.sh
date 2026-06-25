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

specific_config() {
    local my_de="$1"
    local user="$2"

    if [[ $my_de == "xfce" ]]; then
        my_confs=("xfce4" "Thunar" "plank" "terminator" "autostart" "dconf" "gtk-3.0")
        for my_conf in ${my_confs[@]}; do
            mkdir -p "/home/$user/.config/$my_conf"
            cp -rf "$scriptpath/dotfiles/config/$my_conf"/* "/home/$user/.config/$my_conf"/
        done
    fi
}

apply_config() {
    local my_de="$1"
    local user="$2"

    echo -e "${CYN}$user's profile configuration$DEF:"

    for dotfile in "profile" "bashrc" "vimrc"; do
        rm -f "/home/$user/.$dotfile"
    done

    cp -f "$scriptpath/dotfiles/profile" "/home/$user/.profile"

    mkdir -p "/home/$user/.config/bash"
    cp -f "$scriptpath/dotfiles/config/bash"/* "/home/$user/.config/bash"/

    specific_config "$my_de" "$user"

    mkdir -p "/home/$user/.vim"
    cp -f "$scriptpath/dotfiles/vim/vimrc" "/home/$user/.vim"/

    chown -R "$user":"$user" "/home/$user"

    vimplug_url="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    vimplug_dest="/home/$user/.vim/autoload/plug.vim"
    su "$user" -c "mkdir -p $(dirname "$vimplug_dest")"
    su "$user" -c "curl -fLo $vimplug_dest --create-dirs $vimplug_url"
    su "$user" -c "vim +PlugInstall +qall"
}

set_config() {
    local my_de="$1"
    local user="$2"

    if ! (groups "$user" | grep -q sudo); then
        go_sudo="Add user '$user' to 'sudo' group ?"
        if (whiptail --yesno "$go_sudo" 8 78); then
            adduser "$user" sudo
        fi
    fi

    apply_profile="Apply default $my_de config to $user's profile ?"
    if (whiptail --yesno "$apply_profile" 8 78); then
        apply_config "$my_de" "$user"
    fi
}

lightdm_config() {
    cp -f "$scriptpath/conf/lightdm/10_my.conf" /usr/share/lightdm/lightdm.conf.d/
}

pulse_config() {
    pulse_param="flat-volumes = no"
    sed -e "s/; ${pulse_param}/${pulse_param}/" -i /etc/pulse/daemon.conf
}

redshift_config() {
    redshift_conf="\n[redshift]\nallowed=true\nsystem=false\nusers="
    if ! (grep -qvs redshift /etc/geoclue/geoclue.conf); then
        echo -e "$redshift_conf" >> /etc/geoclue/geoclue.conf
    fi
}

add_themes_tweaks() {
    wget -qO- https://git.io/papirus-folders-install | sh
    papirus-folders -t Papirus-Dark -C yaru
    /usr/local/bin/colloid_gtk
    #gruvbox_icons
}

specific_packages(){
    local my_de="$1"

    echo -e "\n${CYN}Desktop environment adaptation (adding/replacing apps)$DEF:"
    if [[ $my_de == "xfce" ]]; then
        apt install -y \
            slick-greeter gvfs-backends redshift-gtk plank arc-theme \
            terminator galculator clapper

        apt purge -y xterm vim-tiny parole* atril* xsane*

        lightdm_config
        pulse_config
        redshift_config
    fi
}

install_desktop() {
    local my_de="$1"

    # prepare sources: add contrib non-free repos and add i386 architecture
    rm -f /etc/apt/sources.list
    cp -f "$scriptpath/conf/apt/sid.sources" /etc/apt/sources.list.d/
    dpkg --add-architecture i386

    echo -e "\n${CYN}System upgrade$DEF:"
    apt update -y
    apt upgrade -y

    echo -e "\n${CYN}Desktop environment installation$DEF:"
    apt install -y \
        linux-headers-amd64 build-essential nfs-common \
        needrestart apt-listbugs \
        vim git curl rsync 7zip htop tree \
        task-desktop task-"$my_de"-desktop \
        papirus-icon-theme breeze-cursor-theme libreoffice-style-sifr \
        firefox gimp steam-installer virt-viewer \
        ttf-mscorefonts-installer

    specific_packages "$my_de"

    (dpkg -l | grep -q "firefox-esr") && apt purge -y firefox-esr

    echo -e "${CYN}System cleanup$DEF:"
    apt autoremove --purge -y

    "$scriptpath"/deploy_systools.sh
    add_themes_tweaks

    for home_folder in /home/*; do
        my_user="$(basename "$home_folder")"
        (grep -q "^$my_user:" /etc/passwd) && set_config "$my_desktop" "$my_user"
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

