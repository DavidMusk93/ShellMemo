#!/bin/bash

_source() {
  [ -f $1 ] && . $1
}

_delete() {
  [ -f $1 ] || [ -d $1 ] && mv $1 /tmp/
  [ -L $1 ] && unlink $1
}

check_zero() {
  [ $1 -eq 0 ]
  return $?
}

check_empty() {
  [ ! "$*" ]
  return $?
}

check_exe() {
  [ -x $1 ]
  return $?
}

check_functor() {
  check_empty $1 && return 1
  [ `type -t $1` = "function" ]
  return $?
}

check_runnable() {
  check_empty $1 && return 1
  check_exe $1 || check_functor $1
  return $?
}

check_pid() {
  check_empty $1 && return 1
  kill -0 $1 &>/dev/null
  return $?
}

child_pid() {
  check_pid $1 || return
  ps -o pid= --ppid $1
}

_killall() {
  check_empty $1 && return
  local _pid=`child_pid $1`
  check_empty $_pid || kill -9 $_pid
  check_pid $1 && kill -9 $1
}

check_rc() {
  return $?
}

assert_empty() {
  check_empty $1 && exit 1
}

assert_exe() {
  [ -x $1 ] || exit 1
}

fatal() {
  local rc=${2-1}
  echo $1
  exit $rc
}

toggle_directory() {
  check_empty $1 && return 1
  [ -d $1 ] || return 1
  cd $1
}

server() {
  local cmd=/usr/bin/python
  local ip= port= ver=
  if check_zero $#; then
    ver=2
    $cmd$ver -m SimpleHTTPServer
  else
    ver=3
    ip=${1%:*}
    port=${1#*:}
    assert_empty $ip
    assert_empty $port
    toggle_directory $2
    $cmd$ver -m http.server $port --bind $ip
  fi
}

installed() {
  dpkg -l | grep -qE "ii[[:blank:]]*$1"
  return $?
}

do_install() {
  local force_mode=
  assert_empty $1
  check_empty $2 && force_mode=-y
  installed $1 || sudo apt install $1 $force_mode
}

batch_install() {
  for pkg in $*; do
    do_install $pkg #&
  done
  #wait
}

which_mode() {
  stat --printf=%a $1
}

write_content() {
  echo -n "$1" > $2
}

peek_content() {
  [ -f $1 ] && cat $1
}

ping_check() {
  local timeout=${2-5}
  ping -c 3 -w $timeout $1
  return $?
}

timestamp() {
  date +"%m_%d-%H_%M_%S"
}

trim() {
  echo -n $*
}

start_with() {
  assert_empty $2
  case $1 in
    $2*)
      return 0;;
  esac
  return 1
}

end_with() {
  assert_empty $2
  case $1 in
    *$2)
      return 0;;
  esac
  return 1
}

check_equal() {
  assert_empty $2
  [ $1 -eq $2 ]
  return $?
}

check_file() {
  _type_check -f $1
  return $?
}

_type_check() {
  assert_empty $2
  case $1 in
    -f|-d|-e)
      [ $1 $2 ]
      return $?;;
  esac
  return 1
}

sizeof() {
  if ! check_file $1; then
    echo 0
    return
  fi
  echo `stat --printf=%s $1`
}

wait_stable() {
  local pre= size=
  size=`sizeof $1`
  check_zero $size && return

  while :; do
    sleep 2
    pre=$size
    size=`sizeof $1`
    check_equal $pre $size && return
  done
}

launch() {
  local name= pid= log_dir=
  local pid_file= log_file=
  local _v= _0= _1= tag=
  local NOHUP=nohup

  _0=`basename $0`
  _0=${_0%.sh}

  _v=($1)
  _1=${_v[0]}
  check_runnable $_1 || fatal "$_1 not runnable"
  check_functor $_1 && NOHUP=
  name=`basename $_1`
  end_with $name ".sh" && tag=@sh
  name=${name%.sh}

  log_dir=${2-/tmp}/$_0
  mkdir -p $log_dir

  pid_file=$log_dir/$name$tag.pid
  log_file=$log_dir/$name$tag.log

  #running check
  pid=`peek_content $pid_file`
  check_pid $pid && return 0

  $NOHUP $1 &>$log_file &
  pid=$!
  sleep 2

  #status check
  check_pid $pid || return 1
  write_content $pid $pid_file
  return 0
}

calc_md5() {
  local md5=
  check_file $1 || return
  md5=`md5sum $1`
  echo ${md5%% *}
}

which_arch() {
  uname -m
}

_0=$0
foo() {
  set -x
  echo $0
  echo $_0
}

case $1 in
  test)
    start_with "onepiece" "one" && echo pass
    end_with "onepiece" "piece" && echo pass
    start_with "onepiece" "hello" || echo pass
    ;;
esac
