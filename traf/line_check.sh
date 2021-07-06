#!/bin/bash

const() {
    ONCALL=0
    ONRETURN=1
    ONERROR=2
}

initialize() {
    const
    state=$ONCALL
    pairs=0
}

retrieve1() {
    echo "$@" | egrep -o 'e_routine=[^ ]+' | cut -d'=' -f2
}

retrieve2() {
    echo "$@" | awk '{print $NF}'
}

onerror() {
    echo "GOTTA!"
}

tick() {
    echo "$((++pairs)) pairs"
}

main() {
    initialize
    #    set -x
    [ "$1" ] && test -f "$1" || exit 1
    local p q
    while read -r l; do
        case $state in
        "$ONCALL")
            p=$(retrieve1 "$l")
            state=$ONRETURN
            ;;
        "$ONRETURN")
            q=$(retrieve2 "$l")
            [ "$p" = "$q" ] && state=$ONCALL || state=ONERROR
            tick
            ;;
        "$ONERROR")
            onerror
            break
            ;;
        esac
    done<"$1"
}
main "$@"
