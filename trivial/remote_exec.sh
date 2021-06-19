#!/bin/bash

initialize() {
    PDSH='pdsh -R exec'
    PDCP='pdcp -R ssh'
    declare -g target_dir
    declare -g script_file
    declare -g cluster
}

print_usage() {
    cat >&1 <<'eof'
remote_exec.sh -t path -s file -c cluster
  -t, remote execute directory
  -s, remote execute script
  -c, indicates cluster information
  -h, print usage
eof
}

rc() {
    return $?
}

parse_args() {
    while getopts ":t:s:c:h" op; do
        case $op in
        t) target_dir=$OPTARG ;;
        s) script_file=$OPTARG ;;
        c) cluster=$OPTARG ;;
        h)
            print_usage
            exit 0
            ;;
        ?)
            echo "unknown option"
            exit 1
            ;;
        esac
    done
    [ "$target_dir" ] && [ "$script_file" ] && [ "$cluster" ] || {
        echo "missing arguments"
        exit 2
    }
}

main() {
    set -x
    initialize
    parse_args "$@"
    $PDCP -w "$cluster" -x "$HOSTNAME" "$script_file" "$target_dir"
    $PDSH -w "$cluster" ssh %h bash "$target_dir/$(basename "$script_file")"
}
main "$@"
