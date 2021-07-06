#!/bin/bash

initialize() {
    _trafci='trafci.sh -u trafodion -p 123 -h localhost'
}

get_tables() {
    $_trafci <<eof
get tables;
quit
eof
}

get_schemas() {
    $_trafci <<eof
get schemas;
quit
eof
}

main() {
    initialize
    set -x
    for ((i = 0; i < $1; ++i)); do
        get_tables &
        get_schemas &
        wait
    done
}
main ${1:-10}
