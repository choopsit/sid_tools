#!/usr/bin/env bash

description="Install/Update Gruvbox-Plus-icon-pack"
# author: Choops <choopsbd@gmail.com>

set -e

DEF="\e[0m"
RED="\e[31m"

THEMES_DIR=/usr/share/icons

icon_theme=gruvbox-plus-icon-pack
git_url="https://github.com/SylEleuth/gruvbox-plus-icon-pack.git"
theme_name=Gruvbox-Plus-Dark


usage() {
    errcode="$1"

    [[ $errcode == 0 ]] && echo "$description"
    echo "Usage:"
    echo "  $(basename "$0") [OPTION]"
    echo "Options:"
    echo "  No option => install $icon_theme"
    echo "  -r,--remove: Remove $icon_theme"
    echo -e "  -h,--help:   Print this help\n"

    exit "$errcode"
}

bye_icon() {
    [[ ! -d "$THEMES_DIR" ]] && echo -e "$icon_theme is not installed\n" && exit 0

    echo "Removing $icon_theme..."

    sudo rm -rf "$THEMES_DIR/gruvbox"*
    rm -rf "$thm_gitpath"
    echo
    exit 0
}

hello_icon() {
    echo "Installing/Updating $icon_theme..."

    if [[ -d "$thm_gitpath" ]]; then
        pushd "$thm_gitpath" >/dev/null
        upd_state="$(git pull | tee /dev/tty)"
        popd >/dev/null
    elif [[ $(whoami) != root ]]; then
        echo "WRN: '$icon_theme' repo must be cloned in '$HOME/Projects/git' before it can be updated"
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

    if ! [[ $upd_state =~ ^(Already up to date.|Déjà à jour.)$ ]] ; then
        if [[ $(whoami) == root ]]; then
            rm -rf "$THEMES_DIR/$theme_name"
            cp -r "$thm_gitpath/$theme_name" "$THEMES_DIR"/
        else
            sudo rm -rf "$THEMES_DIR/$theme_name"
            sudo cp -r "$thm_gitpath/$theme_name" "$THEMES_DIR"/
        fi
    fi 
    echo
}


[[ $1 =~ ^-(h|-help)$ ]] && usage 0

if [[ $(whoami) == root ]]; then
    thm_gitpath=/tmp/"$icon_theme"
else
    (groups | grep -qv sudo) && echo -e "${RED}ERR$DEF: Need 'sudo' rights" && exit 1

    thm_gitpath="$HOME/Projects/git/$icon_theme"

    [[ $1 =~ ^-(r|-remove)$ ]] && bye_icon

    [[ $1 ]] && echo -e "${RED}ERR$DEF: Bad argument" && usage 1

    sudo true
fi

hello_icon

