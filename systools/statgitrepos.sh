#!/usr/bin/env bash

description="Return statuts of git repos in ~/Projects/git"
# author: Choops <choopsbd@gmail.com>

set -e

DEF="\e[0m"
RED="\e[31m"
GRN="\e[32m"
YLO="\e[33m"
CYN="\e[36m"
GRY="\e[37m"


usage() {
    errcode="$1"

    [[ $errcode == 0 ]] && echo "$description"
    echo "Usage:"
    echo "  $(basename "$0") [OPTION]"
    echo "Options:"
    echo -e "  -h,--help: Print this help\n"

    exit "$errcode"
}

get_status() {
    git_folder="$1"

    pushd "$git_folder" > /dev/null

    last_commit="$(git show | awk '/^Date:/ {print $2 " " $3 " " $4 " " $6 " " $5}')"
    commits_count="$(git rev-list --all --count)"
    git_localrepo="$(basename "$git_folder")"
    namelength="${#git_localrepo}"
    seplength=$((28-namelength))
    sep="$(for i in $(seq "$seplength"); do echo -n "-"; done)"
    echo -n -e "${CYN}Repo$DEF: $YLO$git_localrepo ${DEF}x$GRY$sep${DEF}x "
    echo -e "${CYN}Last commit$DEF: $last_commit ($commits_count)"

    status="$(git status -s)"
    if [[ $status ]]; then
        sepupd="                  "
        echo -n -e "${YLO}Uncommited changes$sepupd"
        echo -e "$GRY'---$DEF> $GRY$(git log -1 --pretty=format:%B)$DEF"
        git status -s
    else
        sepupd="                          "
        echo -n -e "${GRN}Up to date$sepupd"
        echo -e "$GRY'---$DEF> $GRY$(git log -1 --pretty=format:%B)$DEF"
    fi

    popd > /dev/null
}


if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 ]]; then
    echo -e "${RED}ERR$DEF: Bad argument" && usage 1
fi

git_stock="$HOME/Projects/git"
[[ ! -d "$git_stock" ]] &&
    echo -e "${RED}ERR$DEF: $git_stock does not exist\n" && exit 1

for folder in "$git_stock"/*; do
    [[ -d "$folder"/.git ]] && get_status "$folder"
done

echo
