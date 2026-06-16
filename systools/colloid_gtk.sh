#!/usr/bin/env bash

description="Install/Update Colloid gtk-theme gruvbox variant"
# author: Choops <choopsbd@gmail.com>

set -e

DEF="\e[0m"
RED="\e[31m"

THEMES_DIR=/usr/share/themes

gtk_theme=Colloid-gtk-theme
git_url="https://github.com/vinceliuice/Colloid-gtk-theme.git"


usage() {
    errcode="$1"

    [[ ${errcode} == 0 ]] && echo "$description"
    echo "Usage:"
    echo "  $(basename "$0") [OPTION]"
    echo "Options:"
    echo "  No option:   Install $gtk_theme"
    echo "  -r,--remove: Remove $gtk_theme"
    echo -e "  -h,--help:   Print this help\n"

    exit "$errcode"
}

bye_gtk() {
    [[ ! -d "$THEMES_DIR" ]] && echo -e "${gtk_theme} is not installed\n" && exit 0

    echo "Removing $gtk_theme..."

    sudo rm -rf "$THEMES_DIR"/Colloid*
    sudo rm -rf "$thm_gitpath"
    echo
    exit 0
}

hello_gtk() {
    echo "Installing/Updating $gtk_theme..."

    pkg_list=/tmp/pkglist

    rm -f "$pkg_list"

    (dpkg -l | grep -q "^ii  sassc") || echo "sassc" >>"$pkg_list"

    if [[ -f "$pkg_list" ]]; then
        if [[ $(whoami) == root ]]; then
            xargs apt install -y < "$pkg_list"
        else
            sudo xargs apt install -y < "$pkg_list"
        fi
    fi

    if [[ -d "$thm_gitpath/.git" ]]; then
        pushd "$thm_gitpath" >/dev/null
        upd_state="$(git pull | tee /dev/tty)"
        popd >/dev/null
    elif [[ $(whoami) != root ]]; then
        echo "WRN: '$gtk_theme' repo must be cloned in '$HOME/Projects/git' before it can be updated"
        read -p "Do it now [y/N] ? " -rn1 go4it
        [[ $go4it ]] && echo

        if [[ ${go4it,} = y ]]; then
            mkdir -p "$HOME/Projects/git"
            git clone "$git_url" "$thm_gitpath"
        else
            exit 0
        fi
    else
        rm -rf "$thm_gitpath"
        git clone "$git_url" "$thm_gitpath"
    fi

    install_script="$thm_gitpath/install.sh"
    sed 's/xfce4-panel -r/echo -n \"\"/g' -i "$install_script"
    sed 's/^\([[:space:]]*\)echo.*gnome-shell.*/\1echo -n \"\"/g' -i "$install_script"

    if ! [[ $upd_state =~ ^(Already up to date.|Déjà à jour.)$ ]] ; then
        if [[ $(whoami) == root ]]; then
            rm -rf "$THEMES_DIR/Colloid-Dark-"*
        else
            sudo rm -rf "$THEMES_DIR/Colloid-Dark-"*
        fi

        if [[ $(whoami) == root ]]; then
            "$install_script" -c dark --tweaks gruvbox --tweaks normal
            #"$install_script" -c dark --tweaks all
        else
            sudo "$install_script" -c dark --tweaks gruvbox --tweaks normal
            #sudo "$install_script" -c dark --tweaks all
        fi
    fi

    pushd "$thm_gitpath" >/dev/null
    git reset --hard HEAD -q
    popd >/dev/null

    echo
}


[[ $1 =~ ^-(h|-help)$ ]] && usage 0

if [[ $(whoami) == root ]]; then
    thm_gitpath="/tmp/$gtk_theme"
else
    (groups | grep -qv sudo) && echo -e "${RED}ERR$DEF: Need 'sudo' rights" && exit 1

    thm_gitpath="$HOME/Projects/git/$gtk_theme"

    [[ $1 =~ ^-(r|-remove)$ ]] && bye_gtk

    [[ $1 ]] && echo -e "${RED}ERR$DEF: Bad argument" && usage 1

    sudo true
fi

hello_gtk

