#!/bin/bash

function sun::initialize() {
    LOCALESGYNDB=~/gitlab/esgyndb
    REMOTEESGYNDB='~/esgyndb'
    REMOTE='v4'
}

function sun::traf::sync_file() {
    [ $1 ] && test -f $1 && {
        set -e
        cd $LOCALESGYNDB
        rsync -avr $1 $REMOTE:$REMOTEESGYNDB/$1
    }
}

function main() {
    sun::initialize
    set -x
    _1=$1
    shift
    case $_1 in
    0 | sync_file) sun::traf::sync_file $* ;;
    esac
}
main $*
