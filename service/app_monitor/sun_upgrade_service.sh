#!/bin/sh

PRIORITY=4

. $SUN_WORK_DIR/shell/common.sh

check_host() {
  [ `uname -m` = x86_64 ]
  return $?
}

second() {
  date +%s
}

fetch() {
  local ss= se= rto=${3-10}

  wget -s -T $rto $1 -O $2
  check_rc || return 1 #file not found
  is_dir `dirname $2` || return 1
  rm -f $2

  ss=`second`
  wget -q -T $rto $1 -O $2
  check_rc || return 1 #download failure
  se=`second`

  echo "fetched `basename $2`, cost $((se-ss)) seconds"
  return 0
}

fetch_md5() {
  fetch $remote_exe_md5 $tmp_exe_md5
  return $?
}

on_start() {
  readonly LOOP_INTERVAL=`expr 30 \* 60 + $PRIORITY`
  check_host && HOST_DEBUG=true || HOST_DEBUG=false

  readonly upgrade_server=http://114.67.71.227:8888
  readonly remote_exe=$upgrade_server/$PROJECT
  readonly remote_exe_md5=$remote_exe.md5

  readonly tmp_exe=/tmp/$PROJECT
  readonly tmp_exe_md5=$tmp_exe.md5
  readonly idle_tag=$tmp_exe@idle

  local_exe=$WORK_DIR/$PROJECT
  ($HOST_DEBUG) && local_exe=$HOME/Downloads/$PROJECT
  has_update=false
  local_md5=`calc_md5 $local_exe`
}

on_updating() {
  fetch $remote_exe $tmp_exe
  return $?
}

on_updated() {
  touch $tmp_exe@last_update@`timestamp`
  return 0
}

on_upgrading() {
  kill_byname $PROJECT
  kill_byfile $LOG_DIR/sun_log_service@sh.pid
  mv $local_exe $WORK_DIR/upgrade/$PROJECT@old@`timestamp`
  mv $tmp_exe $local_exe
}

on_upgraded() {
  has_update=false
}

do_upgrade() {
  check_idle || return 1

  on_upgrading
  on_upgraded
  return 0
}

check_idle() {
  is_file $idle_tag || check_empty `pidof $PROJECT`
  return $?
}

#deprecated, newer first
wait_idle() {
  while :; do
    check_idle && break
    sleep 10
  done
}

check_newer() {
  local md5=`calc_md5 $tmp_exe`
  [ $md5 = $remote_md5 ]
  return $?
}

on_newer() {
  has_update=true
  while :; do
    on_updating && check_newer && on_updated && break
    sleep 60
  done
  do_upgrade
  return 0
}

on_older() {
  ($has_update) && do_upgrade
  return 0 #should return 0
}

run() {
  set -x
  on_start
  ($DEBUG_MODE) || set +x
  remote_md5=

  while :; do
    fetch_md5 && remote_md5=`cat $tmp_exe_md5`
    if ! [ $remote_md5 ]; then
      echo "[`date`]fetch remote md5 failed"
      sleep 60
      continue
    fi

    [ $local_md5 = $remote_md5 ] && on_older || on_newer
    local_md5=$remote_md5
    remote_md5=

    do_sleep $LOOP_INTERVAL
  done
}
run
