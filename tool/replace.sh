#!/bin/bash

sun::replace() {
    sed -i "s#$1#$2#g" $3
}

main() {
    set -x
    [ $1 ] && [ -d $1 ] || return 1
    (
        cd $1
        for i in *.h *.cpp; do
            sun::replace 'namespace sun' 'namespace mxo' $i
            sun::replace 'sun::' 'mxo::' $i
        done
    )
}
main $*
