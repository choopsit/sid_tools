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
        my_confs=("xfce4" "Thunar" "terminator" "Mousepad" "autostart" "dconf" "gtk-3.0")
        for my_conf in ${my_confs[@]}; do
            mkdir -p "/home/$user/.config/$my_conf"
            cp -rf "$scriptpath/dotfiles/config/$my_conf"/* "/home/$user/.config/$my_conf"/
        done

        mkdir -p "/home/$user/.local/share/xfce4"
        cp -rf "$scriptpath/dotfiles/local/share/xfce4"/* "/home/$user/.local/share/xfce4"/

        cp -f "$scriptpath/dotfiles/config/redshif.conf" "/home/$user/.config"/
    fi
}

apply_config() {
    local my_de="$1"
    local user="$2"

    # Spawn temporary minimal .vimrc and install vim-plugs
    cp -f "$scriptpath/dotfiles/vimrc_tmp" "/home/$user/.vimrc"

    vimplug_url="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    vimplug_dest="/home/$user/.vim/autoload/plug.vim"
    su "$user" -c "mkdir -p $(dirname "$vimplug_dest")"
    su "$user" -c "curl -fLo $vimplug_dest --create-dirs $vimplug_url"
    su "$user" -c "vim +PlugInstall +qall"

    # Clean previous conf elements
    for dotfile in "profile" "bashrc" "vimrc"; do
        rm -f "/home/$user/.$dotfile"
    done

    # Deploy conf
    cp -f "$scriptpath/dotfiles/profile" "/home/$user/.profile"

    mkdir -p "/home/$user/.config/bash"
    cp -f "$scriptpath/dotfiles/config/bash"/* "/home/$user/.config/bash"/

    specific_config "$my_de" "$user"

    mkdir -p "/home/$user/.vim"
    cp -f "$scriptpath/dotfiles/vim/vimrc" "/home/$user/.vim"/

    # Fix permissions
    chown -R "$user":"$user" "/home/$user"
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

tweak_papirus() {
    wget -qO- https://git.io/papirus-folders-install | sh
    #papirus-folders -t Papirus-Dark -C nordic
    papirus-folders -t Papirus-Dark -C yaru
}

add_themes_tweaks() {
    if [[ $my_de == "xfce" ]]; then
        tweak_papirus
        /usr/local/bin/colloid_gtk
        /usr/local/bin/gruvbox_icons
    fi
}

specific_packages(){
    local my_de="$1"

    # Desktop environment adaptation (adding/replacing apps)
    if [[ $my_de == "xfce" ]]; then
        apt install -y \
            bluetooth blueman \
            slick-greeter gvfs-backends redshift-gtk xfce4-docklike-plugin \
            arc-theme papirus-icon-theme breeze-cursor-theme \
            terminator galculator clapper soundconverter sound-juicer \
            supertuxkart

        apt purge -y xterm vim-tiny parole* atril* xsane*

        lightdm_config
        pulse_config
        redshift_config
    fi
}

install_desktop_environment() {
    local my_de="$1"

    # Sources cleanup
    rm -f /etc/apt/sources.list
    cp -f "$scriptpath/conf/apt/debian.sources" /etc/apt/sources.list.d/
    dpkg --add-architecture i386

    apt clean -y
    apt autoclean -y

    # System upgrade
    apt update
    apt upgrade -y

    # Prerequisites install
    apt install -y curl

    # Setting Brave repos
    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
    apt update

    # Desktop environment installation
    #browser="firefox"
    browser="brave-browser"
    apt install -y \
        needrestart apt-listbugs \
        linux-headers-amd64 build-essential firmware-iwlwifi nfs-common \
        vim git rsync 7zip htop tree \
        task-desktop task-"$my_de"-desktop \
        libreoffice-style-sifr ttf-mscorefonts-installer \
        $browser gimp steam-installer virt-viewer

    specific_packages "$my_de"

    (dpkg -l | grep -q "firefox-esr") && apt purge -y firefox-esr

    # System cleanup
    apt autoremove --purge -y

    # deploy scripts and add themes
    "$scriptpath"/deploy_systools.sh
    add_themes_tweaks
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

# Choose desktop environment to install with user profile customization or not
desktop_list=(
    "xfce"
    "gnome"
    "kde"
)

desktop_checklist=$(gen_checklist ${desktop_list[@]})

my_desktop=($(whiptail --separate-output --radiolist "Desktop Environment" \
    $((${#desktop_list[@]}+8)) 40 ${#desktop_list[@]} \
        ${desktop_checklist[@]} 3>&1 1>&2 2>&3))

# Set user's config
sudo_users=()
config_users=()
for home_folder in /home/*; do
    my_user="$(basename "$home_folder")"
    if (grep -q "^$my_user:" /etc/passwd); then
        if ! (groups "$my_user" | grep -q sudo); then
            go_sudo="Add user '$my_user' to 'sudo' group ?"
            if (whiptail --yesno "$go_sudo" 8 78); then
                sudo_users+=("$my_user")
            fi
        fi

        apply_profile="Apply default $my_de config to $user's profile ?"
        if (whiptail --yesno "$apply_profile" 8 78); then
            config_users+=("$my_user")
        fi
    fi
done

# Here we go !
install_desktop_environment "$my_desktop"

for sudo_user in ${sudo_users[@]}; do
    adduser "$sudo_user" sudo
done

for config_user in ${config_users[@]}; do
    apply_config "$my_desktop" "$config_user"
done

if (whiptail --yesno "Reboot and enjoy ?" 8 78); then
    reboot
else
    exit 0
fi

