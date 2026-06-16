#!/usr/bin/env bash

description="Deploy 'systools' scripts to /usr/local/bin"
# author: Choops <choopsbd@gmail.com>

set -e

DEF="\e[0m"
RED="\e[31m"
GRN="\e[32m"
CYN="\e[36m"

usage() {
    errcode="$1"

    [[ $errcode == 0 ]] && echo "$description"
    echo "Usage:"
    echo "  '$(realpath "$0") [OPTION]' as root or using 'sudo'"
    echo "Options:"
    echo -e "  -h,--help: Print this help\n"

    exit "$errcode"
}

push_script() {
    script="$1"
    script_name="$(basename "$script")"
    if (cp -f "$script" "/usr/local/bin/${script_name%.*}"); then
        echo -e "${GRN}DONE$DEF: '$script_name' pushed as '/usr/local/bin/${script_name%.*}'"
    else
        echo -e "${RED}ERR$DEF: Failed to push '$script_name'"
    fi
}


if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 ]]; then
    echo -e "${RED}ERR$DEF: Bad argument" && usage 1
fi

[[ $(whoami) != root ]] && echo "${RED}ERR$DEF: Need higher privileges" && usage 1

script_path="$(dirname "$(realpath "$0")")"

echo -e "${CYN}Deploying bash and python systools to '/usr/local/bin/'$DEF..."

for systool in "$script_path/systools"/*; do
    push_script "$systool"
done

