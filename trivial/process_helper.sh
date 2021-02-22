#!/bin/bash

sun::check_cmd() {
    return $?
}

${PERSISTENCE:=false}

sun::replace() {
    test -f $1 || return 1
    local FLAG=
    $PERSISTENCE && FLAG='-i'
    sed -r $FLAG 's#'$2'#'$3'#g' $1
}

sun::kill_by_keyword() {
    __kill() { kill -0 $1 && kill -9 $1; }
    echo "[$(date)] killByKeyword '$1'"
    local pid=$(ps aux | grep "$1[[:blank:]]" | awk '{print $2}')
    [ $pid ] && __kill $pid
    if ! sun::check_cmd && [ "${1:0:7}" = "monitor" ]; then
        killall -9 monitor
    fi
}

sun::check_process() {
    function __show() {
        local pid ppid
        pid=$(pidof $1)
        if [ "$pid" ]; then
            __pid=${pid% *}
            ppid=$(awk '{print $4}' /proc/$__pid/stat)
        fi
        echo "$1,$pid,$ppid"
    }
    for i in tm sqwatchdog service_monitor rc_server pstartd mxssmp mxsscp; do
        __show $i
    done
}

case $1 in
change_server)
    for i in profile trafodion.properties dbconnect.properties; do
        sun::replace $i gy16.esgync esggk79.esgyncn
    done
    ;;
kill)
    set -x
    sun::kill_by_keyword "sqwatchdog"
    sun::kill_by_keyword "monitor COLD"
    ;;
check)
    sun::check_process
    ;;
oe)
    cd $CONFDIR
    load.orderentry.sh -sc 60 -s 4
    run.test.sh -bm orderentry -sc 60 -s 60 -t 3 2>&1 | tee logfile
    ;;
*) ;;
esac
