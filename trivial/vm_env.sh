#!/bin/bash

sun::vm::proxy() {
    PROXYSERVER=192.168.112.1
    PROXYPORT=2081
    case ${1:-enable} in
    1 | enable)
        export http_proxy=$PROXYSERVER:$PROXYPORT
        export https_porxy=$http_proxy
        ;;
    0 | disable)
        export -n http_proxy
        export -n https_porxy
        ;;
    esac
}

sun::vm::predefind_environment() {
    ESGYNHOME=~/esgyndb
    export TOOLSDIR=/opt/home/tools
    export JAVA_HOME=/usr/lib/jvm/java
    export PATH=~/bin:$PATH:$TOOLSDIR/apache-maven-3.3.3/bin:$TOOLSDIR/protobuf-2.5.0/bin
    export SQCERT_DIR=$ESGYNHOME/core/sqf/tmp/sqcert
}

sun::vm::bootstrap() {
    alias ll='ls -al'
    sun::vm::predefind_environment
}
sun::vm::bootstrap
