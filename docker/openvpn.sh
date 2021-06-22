#!/bin/bash

const() {
    SPACE='[[:blank:]]'
    KVSEPARATOR='='
    UNCOMMENTSIGN='#'
    SEDMODIFYFLAG='-i'
}

loadconfig() {
    source compromise.sh
    loadval HOST 1
    loadval SUBHOST 1
}

initialize() {
    const
    datadir=$(whereami)/data
    image=kylemanna/openvpn
}

whereami() {
    dirname "$(realpath $0)"
}

cid() {
    docker ps | grep "$1" | awk '{print $1}'
}

setval() {
    sed $SEDMODIFYFLAG -r 's/^('"$SPACE*$2$SPACE"'*'$KVSEPARATOR"$SPACE"'*).*/\1'"$3"'/' "$1"
}

uncomment() {
    sed $SEDMODIFYFLAG -r 's/^['$UNCOMMENTSIGN']?'"$SPACE"'*('$2'.*)/\1/' "$1"
}

enable_forward() {
    uncomment "$@"
    setval "$@" 1
}

enable_service() {
    local f targetdir
    f=$(basename $1)
    targetdir=/etc/systemd/system
    test -f $targetdir/$f || {
        cp $1 $targetdir
        systemctl enable $f
    }
}

_run() {
    docker run -v "$datadir":/etc/openvpn "$@"
}
__run() {
    _run --log-driver=none --rm "$@"
}

main() {
    set -x
    initialize
    case $1 in
    0 | start) _run -p 1194:1194/udp --cap-add=NET_ADMIN $image ;;
    1 | stop) docker stop "$(cid $image)" ;;
    2 | new)
        u="${2:-default}"
        __run -it $image easyrsa build-client-full "$u" nopass
        __run $image ovpn_getclient "$u" >"$u".ovpn
        ;;
    3 | bootstrap)
        loadconfig
        __run $image ovpn_genconfig -u udp://$host -c -d -D -z -s "$subhost"
        __run -it $image ovpn_initpki
        enable_forward /etc/sysctl.conf net.ipv4.ip_forward
        ;;
    4 | service)
        this=$(realpath $0)
        target=$(dirname $this)/openvpn.service
        cat >$target <<eof
[Unit]
Description = Docker Openvpn
After = network.target docker.service
Requires = docker.service

[Service]
Type = simple
User = ubuntu

ExecStart = $this start
ExecStop = $this stop

[Install]
WantedBy = multi-user.target
eof
        enable_service $target
        ;;
    esac
}
main "$@"
