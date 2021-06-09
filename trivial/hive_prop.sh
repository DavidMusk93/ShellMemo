#!/bin/bash

build_prop() {
    __s() { echo -n "<$1>"; }
    __e() { echo -n "</$1>"; }
    local k v
    k=$1
    v=$2
    shift 2
    cat <<eof
  $(__s property)
    $(__s name)$k$(__e name)
    $(__s value)$v$(__e value)
eof
    [ $# -gt 0 ] && cat <<eof
    $(__s description)$*$(__e description)
eof
    cat <<eof
  $(__e property)
eof
}

declare -A hive_conf
hive_conf["hive.support.concurrency"]="true"
hive_conf["hive.enforce.bucketing"]="true"
hive_conf["hive.exec.dynamic.partition.mode"]="nonstrict"
hive_conf["hive.txn.manager"]="org.apache.hadoop.hive.ql.lockmgr.DbTxnManager"
hive_conf["hive.compactor.initiator.on"]="true"
hive_conf["hive.compactor.worker.threads"]="2"

gene_conf() {
    for i in "${!hive_conf[@]}"; do
        build_prop $i ${hive_conf[$i]}
    done
}

dump_conf() {
    local cmd
    for i in "${!hive_conf[@]}"; do
        cmd+="set $i;"
        cmd+=$'\n'
    done
    swhive <<<"$cmd"
}

main() {
    case $1 in
    0 | gene)
        gene_conf
        ;;
    1 | dump)
        dump_conf
        ;;
    esac
}
main $*
