#!/bin/bash

initialize() {
    DOMODIFY='-i'
    TRAF_VAR=${TRAF_VAR:='/var/lib/trafodion'}
    HEAP_SIZE=512
    KEY=JVM_MAX_HEAP_SIZE_MB
}

setval() {
    sed $DOMODIFY -r 's/^('"$2"'=).*/\1'"$3"'/' $1
}

main() {
    set -ex
    initialize
    cd $TRAF_VAR && {
        setval ms.env $KEY $HEAP_SIZE
        setval ms.env ESP_$KEY $HEAP_SIZE
    }
}
main "$@"
