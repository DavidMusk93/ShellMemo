#!/bin/bash

. ~/.shell.cfg
. $ROOT_DIR/common/functor.sh

MAIN_TASK=run

on_start() {
  _f=file-to-be-watched
  work_dir=$ROOT_DIR/service/watch_upload
}

main_task() {
  [ $_task = $MAIN_TASK ]
  return $?
}

do_clean() {
  local pid= _0=
  _0=`basename $0`
  _0=${_0%.sh}

  for f in `ls /tmp/$_0/*.pid`; do
    pid=`peek_content $f`
    _killall $pid
  done
}

run() {
  on_start
  case $1 in
    $MAIN_TASK)
      launch "$work_dir/_watch_upload.sh $work_dir/upgrade/$_f"
      launch "server 0.0.0.0:8888 $work_dir/upgrade"
      ;;
    clean)
      do_clean;;
    test)
      echo $0
      foo
      ;;
  esac
}

set -x

_task=${1-$MAIN_TASK}
run $_task
