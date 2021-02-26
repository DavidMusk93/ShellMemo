#!/bin/bash

sun::trace_write() {
    strace -f -p$TARGETPID -s64 -e write 2>&1
}

sun::on_querypwd() {
    SUBPID=${2%]} && kill -0 $SUBPID || return 1
    echo "123456" >/proc/$SUBPID/fd/4
}

main() {
    TARGETPID=$1
    kill -0 $TARGETPID || return 1
    sun::trace_write | grep --line-buffered "'s password:" | while read -r line; do
        echo "QUERY PASSWROD:$line"
        sun::on_querypwd $line
    done
}
sun::main $*
