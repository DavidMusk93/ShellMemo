#!/bin/bash

sun::remote::initialize() {
    PDSH='pdsh -R exec'
    PDCP='pdcp -R ssh'
    SSHCMD='ssh %h'
    [[ $0 == -* ]] || {
        SCRIPTSELF=$(basename $0)
    }
}
sun::remote::initialize

sun::remote_bash() {
    local CLUSTER="$1"
    shift
    $PDSH -w $CLUSTER $SSHCMD bash "$@"
}