#!/bin/bash

space() {
    local i s
    for ((i = 0; i < $1; ++i)); do
        s+=' '
    done
    echo -n "$s"
}

item() {
    cat <<eof
<$1>
  $2
</$1>
eof
}

property() {
    item 'property' "\n$(item 'name' $1)\n$(item 'value' $2)\n"
}

# @ref https://unix.stackexchange.com/questions/99350/how-to-insert-text-before-the-first-line-of-a-file
addprop() {
    ex $1 <<eof
/^<conf/a
    <property>
      <name>$2</name>
      <value>$3</value>
    </property>
.
x
eof
}

enableforward() {
    addprop $1 dcs.server.forwarder.enable true
}

main() {
    #sed '/^<configuration>/a '"$(property dcs.server.forwarder.enable true)" $1
    enableforward $1
}
main "$@"
