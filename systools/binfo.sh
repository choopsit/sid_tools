#!/usr/bin/env bash

description="Display minimal system informations"
# author: Choops <choopsbd@gmail.com>

set -e

DEF="\e[0m"
RED="\e[31m"
GRN="\e[32m"
YLO="\e[33m"
BLU="\e[34m"
PUR="\e[35m"
CYN="\e[36m"
GRY="\e[37m"


usage() {
    errcode="$1"

    [[ $errcode == 0 ]] && echo "$description"

    echo "Usage:"
    echo "  '$(basename "$0") [OPTION]' as root or using sudo"
    echo "Options:"
    echo -e "  -h,--help: Print this help\n"

    exit "$errcode"
}

trim() {
    set -f
    # shellcheck disable=2048,2086
    set -- $*
    printf '%s\n' "${*//[[:space:]]/}"
    set +f
}

get_ppid() {
    ppid="$(grep -i -F "PPid:" "/proc/${1:-$PPID}/status")"
    ppid="$(trim "${ppid/PPid:}")"
    printf "%s" "$ppid"
}

get_process_name() {
    name="$(< "/proc/${1:-$PPID}/comm")"
    printf "%s" "$name"
}


[[ $1 =~ ^-(h|-help)$ ]] && usage 0

[[ $1 ]] && echo -e "${RED}ERR$DEF: Bad argument" && usage 1

palette="\e[30m#\e[31m#\e[32m#\e[33m#\e[34m#\e[35m#\e[36m#\e[37m#"

colors=("$RED" "$GRN" "$YLO" "$BLU" "$PUR" "$CYN" "$GRY")
rand=$[$RANDOM % ${#colors[@]}]
col_deb="${colors[$rand]}"

col_usr="$GRN"
[[ $USER = root ]] && col_usr="$RED"

my_id="$col_usr$USER$DEF@$YLO$(hostname -s)$DEF"
my_os="${CYN}OS$DEF: $(awk -F\" '/^PRETTY/ {print $2}' /etc/os-release)"
my_kernel="${CYN}Kernel$DEF: $(uname -sr)"

myshell="$(basename "$SHELL")"
my_shell="${CYN}Shell$DEF: $myshell"
if [[ $myshell == bash ]]; then
    my_shell+=" ${BASH_VERSION%(*}"
else
    shell_version="$("$SHELL" --version 2>&1)"
    # Remove unwanted info
    shell_version=${shell_version/, version}
    shell_versiob=${shell_version/xonsh\//xonsh }
    Shell_version=${shell_version/options*}
    shell_version=${shell_version/\(*\)}
    my_shell+=" $shell_version"
fi

# Check $PPID for terminal emulator.
while [[ -z "$term" ]]; do
    parent="$(get_ppid "$parent")"
    [[ -z "$parent" ]] && break
    name="$(get_process_name "$parent")"

    case ${name// } in
        "${SHELL/*\/}"|*"sh"|"screen"|"su"*|"newgrp") ;;

        "login"*|*"Login"*|"init"|"(init)")
            term="$(tty)"
            ;;

            "ruby"|"1"|"tmux"*|"systemd"|"sshd"*|"python"*|\
                "USER"*"PID"*|"kdeinit"*|"launchd"*|"bwrap")
            break
            ;;

        "gnome-terminal-") term="gnome-terminal" ;;
        "urxvtd")          term="urxvt" ;;
        *"nvim")           term="Neovim Terminal" ;;
        *"NeoVimServer"*)  term="VimR Terminal" ;;

        *)
            # Fix issues with long process names on Linux.
            [[ $os == Linux ]] && term=$(realpath "/proc/$parent/exe")

            term="${name##*/}"

                # Fix wrapper names in Nix.
                [[ $term == .*-wrapped ]] && {
                    term="${term#.}"
                                    term="${term%-wrapped}"
                }
            ;;
    esac
done

sept="\t\t    "
#sept="\t\t\t"
if [[ ${#my_shell} -lt 7 ]]; then
    sept="\t\t\t    "
    #sept="\t\t\t\t"
elif [[ ${#my_shell} -gt 14 ]];then
    sept="\t    "
    #sept="\t\t"
fi
my_terminal="$sept${CYN}Terminal$DEF: $term"
my_terminal+=" $(dpkg-query -W "$term" | awk '{print $2}')"

my_packages="${CYN}Packages$DEF: $(dpkg -l | grep '^ii' | wc -l)"

mydesktop=""
if { [[ $XDG_CURRENT_DESKTOP ]] || [[ $DESKTOP_SESSION ]] ; }; then
    if [[ $XDG_CURRENT_DESKTOP ]]; then
        if [[ $XDG_CURRENT_DESKTOP == XFCE ]]; then
            de="$DESKTOP_SESSION $(dpkg-query -W xfce4 | awk '{print $2}')"
        elif [[ $XDG_CURRENT_DESKTOP == GNOME ]]; then
            de="${XDG_CURRENT_DESKTOP,,} $(dpkg-query -W gnome | awk '{print $2}')"
        else
            de="$XDG_CURRENT_DESKTOP"
        fi
    else
        de="$DESKTOP_SESSION"
    fi
    my_desktop="\t    ${CYN}DE$DEF: $de"
    #my_desktop="\t\t${CYN}DE$DEF: $de"
fi

my_ram="$(free -m | awk '/^Mem:/ {print $3 "/" $2 "MB"}')"
my_swap="$(free -m | awk '/^Swap:/ {print $3 "/" $2 "MB"}')"
my_memory="${CYN}RAM$DEF: $my_ram\t    ${CYN}Swap$DEF: $my_swap"
#my_memory="${CYN}RAM$DEF: $my_ram\t\t${CYN}Swap$DEF: $my_swap"

my_uptime="${CYN}Uptime$DEF: $(uptime -p | sed 's/up //')"

echo -e "$col_deb   .a#\$\$#a.   $my_id"
echo -e "$col_deb  d#\"    \"#b  $my_os"
echo -e "$col_deb  ##  d\"  ##  $my_kernel"
echo -e "$col_deb  \"#. \"#\$#\"   $my_shell$my_terminal"
echo -e "$col_deb   \"#.        $my_packages$my_desktop"
echo -e "$col_deb     \"+.      $my_memory"
echo -e "   $palette   $my_uptime\n"

