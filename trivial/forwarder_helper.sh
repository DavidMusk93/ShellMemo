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
}

main() {
    sun::initialize
    set -x
    ACTION=$1
    shift
    case $ACTION in
    0 | cleanup)
        for i in $*; do
            if [ $HOSTNAME = $i ]; then
                main 1
            else
                $PDCP -w $i -x $HOSTNAME $EXECUTOR $TARGETDIR
                $PDSH -w $i $SSHCMD bash $EXECUTOR 1
            fi
        done
        ;;
    1 | cleanup-impl) sun::forwarder_cleanup ;;
    2 | install)
        (
            cd ~/Documents/github/c-playground/socket
            rm -f $MONITORTAR
            tar -zcvf $MONITORTAR ./monitor
            $PDCP -w c[1-3] -x $HOSTNAME $MONITORTAR $MONITORDIR
            $PDSH -w c[1-3] $SSHCMD bash $EXECUTOR 3
        )
        ;;
    3 | install-impl) sun::forwarder_install ;;
    esac
}
main $*
