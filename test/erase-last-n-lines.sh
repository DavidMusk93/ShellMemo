#!/bin/bash

_fn_1(){
    sed -e :a -e '$d;N;2,'$1'ba' -e 'P;D;' $2
}

_fn_2(){
    sed -e :a -e 'N;1,'$1'!{P;$d;D;};ba' $2
}

eraseLastNLines(){
    local RE='^[0-9]+$'
    [[ $1 =~ $RE ]] && test -f $2 || return 1
    local N=`wc -l $2`
    [ $1 -gt $N ] && return 2
    _fn_2 $1 $2
}

main(){
    local N=9 F=in.txt
    >$F
    for i in {a..z};do echo $i>>$F;done
    _fn_1 $N $F
    echo '******'
    _fn_2 $N $F
}
main
