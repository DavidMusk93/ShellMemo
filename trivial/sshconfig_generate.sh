#!/bin/bash

sun::initialize() {
    TMPDIR=/tmp
    CONFIGFILE=$TMPDIR/ssh.config
}

sun::generate() {
    rm -f $CONFIGFILE
    for i; do
        cat >>$CONFIGFILE <<eof
Host t$i
    Hostname 10.10.12.$i
    User root

eof
    done
}

main() {
    sun::initialize
    set -x
    sun::generate "$@"
}
main "$@"
