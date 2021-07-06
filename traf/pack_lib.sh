#!/bin/bash

initialize() {
    declare -g targetdir
    declare -g exe
}

copy_dependencies() {
    for i in $(ldd $exe | awk '{print $3}'); do
        case $i in
        /*) rsync -R -avr "$i" . ;;
        esac
    done
    cp $exe .
}

pack_library() {
    p=$(basename $exe)
    [ $p = $exe ] && exe=$(which $exe)
    mkdir -p $targetdir/$p
    (
        set -e
        cd $targetdir/$p
        copy_dependencies
        cd $targetdir
        tar zcvf $p.tar.gz $p
    )
}

main() {
    set -x
    initialize
    exe=$1
    targetdir=${2:-/tmp}
    pack_library
}
main "$@"
