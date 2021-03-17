#!/bin/bash

sun::cleanup_core() {
    find -name core.* -exec rm -f {} \;
    find -name proc_* -exec rm -f {} \;
}

sun::naheap_check() {
    [ $1 ] && kill -0 $1 || return 1
    gdb -p $1 <<'eof'
p _net_heap.la_
p _stmt_heap.la_
quit
eof
}
