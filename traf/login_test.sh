#!/bin/bash

initialize() {
    counter=0
    pid=$(pidof mxosrvr)
    [ "$pid" ] || exit 1
}

has_spawn() {
    [ "$pid" != "$(pidof mxosrvr)" ]
}

onfinish() {
    local p
    p=$(pidof stap)
    [ "$p" ] && kill -SIGINT "$p"
}

#onfailure() {
#    dcsstop
#}

main() {
    set -x
    initialize
    while :; do
        echo "****** $((++counter))-th ******"
        trafci.sh -u trafodion -p traf123 -h localhost <<'eof'
get tables;
quit
eof
        sleep 1
        has_spawn && break
    done
    onfinish
}
main "$@"
