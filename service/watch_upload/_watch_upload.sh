#!/bin/bash

. ~/.shell.cfg
. $ROOT_DIR/common/functor.sh

assert_empty $1
_1=$1

on_start() {
  local target=`basename $_1`
  readonly work_dir=`dirname $_1`
  readonly watch_target=/tmp/$target
  readonly md5_target=$watch_target.md5

  mkdir -p $work_dir
  touch $watch_target

  #check dependency
  do_install inotify-tools

  set -x
}

on_modify() {
  local md5=
  wait_stable $watch_target
  md5=`md5sum $watch_target`
  md5=${md5%% *}
  write_content $md5 $md5_target

  mv $watch_target $work_dir
  mv $md5_target $work_dir

  touch $watch_target
  #sleep 60
}

on_start

while inotifywait -e modify $watch_target; do
  on_modify
done
