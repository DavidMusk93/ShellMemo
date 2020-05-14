#!/bin/bash

function abort() {
  echo $*
  exit 1
}

function docker::pidof() {
  docker inspect $1 | sed -E -n 's/[[:blank:]]+"Pid": ([0-9]+),/\1/p'
}

function docker::nsenter() {
  [ $1 ] || abort usage: $0 container-id/pid
  export LC_ALL=C
  local pid=$1
  [ ${#pid} -eq 12 ] && pid=`docker::pidof $1`
  sudo nsenter -m -u -n -p -i -t $1 /bin/bash
}
