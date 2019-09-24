#!/bin/bash

. ./functor.sh

rm_prefix() {
  local from=$1 to=
  to=${from#$2}

  [ $from = $to ] || mv $from $to
}

sub() {
  is_file $1 || return
  sed -i "s/$2/$3/g" $1
  sed -i "s/${2^^}/${3^^}/g" $1
}

run() {
  local target=(`ls *.sh`) i=
  for i in ${target[@]}; do
    sub $i $1 $2
    rm_prefix $i $1
  done
}

set -x

assert_empty $2
_1=${1,,}
_2=${2,,}

run $_1 $_2
