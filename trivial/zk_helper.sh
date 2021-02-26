#!/bin/bash

main() {
    case $1 in
    delete-hbase-master | 0)
        swzkcli <<'eof'
delete /hbase/master
eof
        return 0
        ;;
    esac
    return 1
}
main $* && exit 0

ZKROOT=/trafodion/1
ZKREGISTERED=$ZKROOT/dcs/servers/registered
LOG=/tmp/zk-helper.log

swzkcli <<eof &>$LOG
ls $ZKREGISTERED
eof

set -x

cmds=
REGISTERED=$(tail -n 1 $LOG)
for i in $(echo $REGISTERED | tr -d '[],'); do
    cmds+="get $ZKREGISTERED/$i"$'\n'
done

echo "$cmds" | swzkcli
