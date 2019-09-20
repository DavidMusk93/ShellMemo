#!/bin/sh

. ~/.shell.cfg
. $ROOT_DIR/common/functor.sh

fetch_md5() {
  rm -f $tmp_exe_md5
  wget $remote_exe_md5 -O $tmp_exe_md5
  check_rc || return
  cat $tmp_exe_md5
}

on_start() {
  readonly exe=upload_service
  readonly upgrade_server=http://127.0.0.1:8888
  readonly remote_exe=$upgrade_server/$exe
  readonly remote_exe_md5=$remote_exe.md5

  #fetch to /tmp, then move to working directory
  readonly tmp_exe=/tmp/$exe
  readonly tmp_exe_md5=$tmp_exe.md5

  #touch tag file on idle, remove it on working
  readonly idle_tag=$tmp_exe@idle

  local_exe=$HOME/Documents/$exe
  has_update=false
  local_md5=`calc_md5 $local_exe`
}

on_update() {
  rm -f $tmp_exe
  wget $remote_exe -O $tmp_exe
  return $?
}

safe_kill() {
  [ $1 ] && kill -0 $1 && kill -9 $1
}

do_upgrade() {
  local pid=
  check_idle || return 1

  pid=`pidof $exe`
  safe_kill $pid

  mv $tmp_exe $local_exe
  chmod +x $local_exe
  touch /tmp/$exe@last_update@`timestamp`
  has_update=false
  return 0
}

check_idle() {
  [ -f $idle_tag ] || [ ! `pidof $exe` ]
  return $?
}

#deprecated, newer first
wait_idle() {
  while :; do
    check_idle && break
    sleep 10
  done
}

on_newer() {
  has_update=true
  while :; do
    on_update && break
    sleep 60
  done
  do_upgrade
  sleep 10
}

on_older() {
  if ($has_update); then
    do_upgrade
    sleep 10
    return
  fi
  sleep 100
}

run() {
  set -x
  on_start
  local remote_md5=

  while :; do
    remote_md5=`fetch_md5`
    [ $remote_md5 ] || break

    [ $local_md5 = $remote_md5 ] && on_older || on_newer
    local_md5=$remote_md5
  done
}
run
