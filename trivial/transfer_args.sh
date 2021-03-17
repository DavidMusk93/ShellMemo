#!/bin/bash

function f1() {
    echo @f1#$# $*
}

function f2() {
    echo @f2#$# "$@"
}

main() {
    echo @main#$#
    f1 $*
    f2 "$@"
}
main "$@"
