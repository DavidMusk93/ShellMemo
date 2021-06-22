#!/bin/bash

_build_color() {
    echo -n '\e['"$1"'m'
}

initialize_color() {
    COLORRED=$(_build_color 31)
    COLORRESET=$(_build_color 0)
}

logfatal() {
    initialize_color
    echo -e "$COLORRED$*$COLORRESET"
    exit 1
}

_yes() {
    [ "$1" ] || return 1
    [ "$1" -eq 0 ] && return 1
    case $1 in
    "FALSE" | "False" | "false") return 1 ;;
    esac
    return 0
}

# If a val is sensitive, load it form env may be a better choice.
#  arguments:
#   $1, val name set by 'export key=val'
#   $2, optional/required
loadval() {
    eval "${1,,}=${!1}"
    _yes "$2" && ! [ "${!1}" ] && logfatal \""$1"\" is not set
}
