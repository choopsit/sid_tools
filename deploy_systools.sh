#!/usr/bin/env bash

description="Deploy 'systools' scripts to /usr/local/bin"
# author: Choops <choopsbd@gmail.com>

set -e

usage() {
    errcode="$1"

    [[ $errcode == 0 ]] && echo "$description"
    echo "Usage:"
    echo "  '$(realpath "$0") [OPTION]' as root or using 'sudo'"
    echo "Options:"
    echo "  -h,--help: Print this help"
    echo

    exit "$errcode"
}

push_script() {
    script="$1"
    script_name="$(basename "$script")"
    if (cp -f "$script" /usr/local/bin/"${script_name%.*}"); then
        echo "DONE: '$script' pushed as '/usr/local/bin/${script_name%.*}'"
    else
        echo "ERR: Failed to push '$script_name'"
    fi
}


if [[ $1 =~ ^-(h|-help)$ ]]; then
    usage 0
elif [[ $1 ]]; then
    echo "ERR: Bad argument" && usage 1
fi

[[ $(whoami) != root ]] && echo "ERR: Need higher privileges" && usage 1

script_path="$(dirname "$(realpath "$0")")"

echo "Deploying bash and python systools to '/usr/local/bin/'..."

for systool in "$script_path"/systools/*; do
    push_script "$systool"
done

