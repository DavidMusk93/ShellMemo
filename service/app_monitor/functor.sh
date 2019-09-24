#!/bin/sh

check_rc() {
  return $?
}

assert_rc() {
  check_rc $? || exit 1
}

trim() {
  echo $*
}

check_empty() {
  [ ! "$*" ]
  return $?
}

assert_empty() {
  check_empty $* && exit 1
}

check_pid() {
  check_empty $1 && return 1
  kill -0 $1 &>/dev/null
  return $?
}

check_pid_bylazy() {
  check_empty $1 && return 1
  local delay=${2-2}

  sleep $delay
  check_pid $1
  return $?
}

kill_byid() {
  check_pid $1 && kill -9 $1
}

kill_byname() {
  check_empty $1 && return
  kill_byid `pidof $1`
}

kill_byfile() {
  is_file $1
  kill_byid `pcontent $1`
}

list() {
  echo *
}

timestamp() {
  date +"%m_%d-%H_%M_%S"
}

_type_check() {
  check_empty $2 && return 1
  case $1 in
    -f|-d|-e)
      [ $1 $2 ]
      return $?;;
  esac
  return 1
}

is_file() {
  _type_check -f $1
  return $?
}

is_dir() {
  _type_check -d $1
  return $?
}

calc_md5() {
  local md5=
  is_file $1 || return
  md5=`md5sum $1`
  echo ${md5%% *}
}

do_gzip() {
  is_file $1 || return
  (cd `dirname $1` && gzip `basename $1`)
}

fsize() {
  local size=
  if ! is_file $1; then
    echo 0
    return
  fi
  size=`ls -l $1 | tr -s ' ' | cut -d ' ' -f 5`
  echo `expr $size / 1024` #Kb
}

fcount() {
  if ! is_dir $1; then
    echo 0
    return
  fi
  #(cd $1 && list | wc -w)
  #find $1 -maxdepth 1 -type f | wc -w
  ls $1/ | wc -w
}

record_pid() {
  wcontent $! $1
}

wcontent() {
  echo -n "$1" > $2
}

pcontent() {
  is_file $1 && cat $1
}

check_priority() {
  is_file $1 || return 1
  local PRIORITY= _s=
  _s=`grep '^PRIORITY=' $1`
  check_empty $_s && return 1
  eval "$_s"
  eval "_p$PRIORITY=$1" #dynamic declare
  return 0
}

on_signal() {
  if ! check_empty $_sleep_pid; then
    kill -9 $_sleep_pid && sleep 2
  fi
}

do_sleep() {
  _sleep_pid=
  local sec=

  sec=`eval "expr $*"`
  sleep $sec &
  _sleep_pid=$!
  wait $_sleep_pid
  _sleep_pid=
}

launch() {
  is_dir $2 || return 1 #log directory not found
  local name= pid= pid_file= log_file= runnable=
  is_file $1 || return 1

  name=`basename $1`
  runnable=/tmp/$name
  cp $1 $runnable

  name=${name%.sh}

  pid_file="$2/$name@sh.pid"
  log_file="$2/$name@sh.log"

  #already-running check
  check_pid `pcontent $pid_file` && return 0

  chmod +x $runnable
  nohup sh $runnable &>$log_file &
  pid=$!

  if ! check_pid_bylazy $pid; then
    echo "launch $1 failed"
    return 1
  fi

  wcontent $pid $pid_file
  return 0
}
