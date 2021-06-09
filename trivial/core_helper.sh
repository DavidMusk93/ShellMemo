#!/bin/bash

function sun::const::code() {
    NOTFOUND=1
}

function sun::const::string() {
    BR="@@@@@@"
}

function sun::initialize() {
    sun::const::code
    sun::const::string
    TMPDIR='/tmp'
    DEBUGFILE='debug-pnode.txt'
    MXOSRVR=mxosrvr
    EXE=
    LISTENERTAG=tcpip_listener
    THREADTAG='LWP '
    PIDDELIM=':'
    PIDMAP=$TMPDIR/mxo.listener.pid.map
    STATUSMAP=$TMPDIR/mxo.listener.status.map
    SCRIPTDIR=$( (cd $(dirname $0) && pwd))
    CLUSTER='t11,t14,t21'
    REMOTESCRIPTDIR='/opt'
    REMOTEHELPER=$SCRIPTDIR/remote_helper.sh
}

function sun::safe::cd() {
    test -d $1 && cd $1 || exit $NOTFOUND
}

function sun::core::dump_mxosrvr() {
    for i in $(pidof mxosrvr); do
        gcore $i &
    done
    wait
}

function sun::core::check_client_status() {
    #[ $1 ] && test -f $1 || return 1
    test -f $DEBUGFILE || cat >$DEBUGFILE <<'eof'
info threads
thread 8
bt
frame 1
info locals
p *pnode
eof
    EXE=$(find /opt/trafodion -name $MXOSRVR)
    [ $EXE ] && {
        for i in core.*; do
            echo "$BR $i"
            gdb -q $EXE $i <<eof
source -v $DEBUGFILE
eof
            echo $BR
        done
    }
}

function sun::trace::network() {
    [ $1 ] && kill -0 $1 2>/dev/null && {
        LOGFILE=${2:-trace.network}
        strace -f -ttt -s 256 -p $1 -e trace=%network 2>&1 | tee $LOGFILE
    }
}

function sun::network_tuning() {
    __d() { echo $((2 * $1)); }
    sysctl -w net.ipv4.tcp_early_retrans=0
    sysctl -w net.ipv4.ipfrag_time=60
    sysctl -w net.ipv4.tcp_mtu_probing=2
    sysctl -w net.ipv4.tcp_mem="378357 $(__d 504478) $(__d 756714)"
    sysctl -w net.ipv4.tcp_rmem="4096 $(__d 87380) 6291456"
    sysctl -w net.ipv4.tcp_wmem="4096 $(__d 16384) 4194304"
}

function sun::mxo::list_listener_impl() {
    local pid line
    __retrieve_sub_pid() {
        pid=$(echo "$@" | egrep -o "${THREADTAG}[[:digit:]]+")
        pid=${pid#$THREADTAG}
    }
    __has_listener_tag() {
        echo "$@" | grep -q $LISTENERTAG
    }
    set +x
    while read -r line; do
        case $line in
        Thread*) __retrieve_sub_pid $line ;;
        \#*) __has_listener_tag $line && break ;;
        esac
    done < <(pstack $1)
    set -x
    echo "$1$PIDDELIM$pid" >$PIDMAP.$1
}

function sun::mxo::list_listener() {
    for i in $(pidof $MXOSRVR); do
        sun::mxo::list_listener_impl $i &
    done
    wait
    cat $PIDMAP.* >$PIDMAP
    rm -f $PIDMAP.*
    cat $PIDMAP
}

function sun::mxo::peek_listener_status() {
    __dump_stack() {
        local line FINISH
        FINISH=false
        while read -r line; do
            case $line in
            Thread*)
                $FINISH && break
                if echo $line | grep -q $2; then
                    echo $line >&$3
                    FINISH=true
                fi
                ;;
            \#*) $FINISH && echo $line >&$3 ;;
            esac
        done < <(pstack $1)
    }
    __dump_status() {
        set +x
        local fd
        exec {fd}>$STATUSMAP.$1
        echo "$BR $1>$2" >&$fd
        #pstack $1 | grep -A10 -m1 "$THREADTAG$2" >&$fd
        __dump_stack $1 $2 $fd
        echo $BR >&$fd
        echo >&$fd
        set -x
    }
    while
        read -d$PIDDELIM main
        read sub
    do
        __dump_status $main $sub &
    done < <(cat $PIDMAP)
    wait
    cat $STATUSMAP.* >$STATUSMAP
    rm -f $STATUSMAP.*
    cat $STATUSMAP
}

function main() {
    set -x
    sun::initialize
    sun::safe::cd $TMPDIR
    case $1 in
    0 | dump) sun::core::dump_mxosrvr ;;
    1 | check) sun::core::check_client_status ;;
    2 | network) sun::trace::network $2 $3 ;;
    3 | tuning) sun::network_tuning ;;
    4 | list) sun::mxo::list_listener ;;
    5 | status) sun::mxo::peek_listener_status ;;
    pstatus)
        source $REMOTEHELPER
        sun::remote_bash $CLUSTER $REMOTESCRIPTDIR/$SCRIPTSELF status
        ;;
    plist)
        source $REMOTEHELPER
        sun::remote_bash $CLUSTER $REMOTESCRIPTDIR/$SCRIPTSELF list
        ;;
    pcopy)
        source $REMOTEHELPER
        $PDCP -w $CLUSTER -x $HOSTNAME $SCRIPTDIR/$SCRIPTSELF $REMOTESCRIPTDIR/$SCRIPTSELF
        ;;
    esac
}
main $*
