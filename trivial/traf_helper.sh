#!/bin/bash

sun::dump_mxosrvrstderr() {
    set -x
    __valid_mxosrvr() {
        kill -0 $1 2>/dev/null && pidof mxosrvr | grep -q $1
    }
    __valid_mxosrvr $1 || return 1
    STDERR=$(realpath /proc/$1/fd/2)
    tail -f $STDERR | tee dump_mxosrvrstderr.$1
}

sun::cleanup_corefile() {
    set -x
    find -name 'core.*' -exec rm -f {} \;
    find -name 'core-*' -exec rm -f {} \;
}

main() {
    case $1 in
    0) sun::dump_mxosrvrstderr $2 ;;
    1) sun::cleanup_corefile ;;
    esac
}
main $*
