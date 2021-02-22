#!/bin/bash

#LMONITOR=./core/sqf/export/bin64d/monitor
#LPKILLALL=./core/sqf/sql/scripts/pkillall
#RMONITOR=/opt/trafodion/esgyndb/export/bin64d/monitor
#RPKILLALL=/opt/trafodion/esgyndb/sql/scripts/pkillall

LOCAL_MXOSRVR=./core/sqf/export/bin64d/mxosrvr
REMOTE_MXOSRVR=/opt/trafodion/esgyndb/export/bin64/mxosrvr

SOURCEDIR=/home/public/Documents/esgyndb.mxosrvr
CURRENTDIR=$(pwd)

main() {
    _1=$1
    done_pre_op=false
    done_post_op=false
    # execute dcsstop & dcsstart in one node, would take effects on all nodes
    __pre_op() {
        $done_pre_op && return 0
        done_pre_op=true
        case ${_1:-0} in
        copy | 0)
            ssh $SERVER "dcsstop"
            # make sure all mxosrvrs exit
            sleep 5
            ;;
        check | 1)
            md5sum $LOCAL_MXOSRVR
            ;;
        esac
    }
    __post_op() {
        $done_post_op && return 0
        done_post_op=true
        ssh $SERVER "dcsstart"
    }
    __remote_copy() {
        scp $2 $1:$3
    }
    cd $SOURCEDIR
    for i in {7..10}; do
        SERVER="trafodion@10.10.10.$i"
        __pre_op
        case ${1:-0} in
        copy | 0)
            __remote_copy $SERVER $LOCAL_MXOSRVR $REMOTE_MXOSRVR
            ;;
        check | 1)
            # no need to do post op
            done_post_op=true
            ssh $SERVER "md5sum $REMOTE_MXOSRVR"
            ;;
        esac
    done
    __post_op
    cd $CURRENTDIR
}
set -x
main $*
