#!/bin/bash

sun::forwarder_cleanup() {
    KEY=forwarder
    pkill -9 $KEY.daemon
    pkill -9 $KEY
    #for i in ipc lock log; do rm -f /tmp/$KEY.$i; done
    rm -f /tmp/$KEY.{ipc,lock,log}
}

sun::forwarder_install() {
    cd $MONITORDIR
    rm -rf monitor
    tar -zxvf $MONITORTAR
    cd monitor/cmake-build-debug
    rm -rf * && cmake .. && make
    nohup ./forwarder &
}

sun::initialize() {
    PDSH='pdsh -R exec'
    PDCP='pdcp -R ssh'
    SSHCMD='ssh %h'
    TARGETDIR=/opt
    EXECUTOR=$TARGETDIR/$(basename $0)
    MONITORTAR=monitor.tar.gz
    MONITORDIR=/home/esg
    CLUSTER='c[1-3]'
}

main() {
    sun::initialize
    set -x
    ACTION=$1
    shift
    case $ACTION in
    dispatch) $PDCP -w $CLUSTER -x $HOSTNAME $0 $TARGETDIR ;;
    0 | cleanup) $PDSH -w $CLUSTER $SSHCMD bash $EXECUTOR 1 ;;
    1 | cleanup-impl) sun::forwarder_cleanup ;;
    2 | install)
        (
            cd ~/Documents/github/c-playground/socket
            rm -f $MONITORTAR
            tar -zcvf $MONITORTAR ./monitor
            $PDCP -w $CLUSTER -x $HOSTNAME $MONITORTAR $MONITORDIR
            $PDSH -w $CLUSTER $SSHCMD bash $EXECUTOR 3
        )
        ;;
    3 | install-impl) sun::forwarder_install ;;
    esac
}
main $*
