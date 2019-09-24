#!/bin/sh

PRIORITY=2

. $SUN_WORK_DIR/shell/common.sh

create_pipe() {
  check_empty $1 && return 1
  is_dir `dirname $1` || return 1

  rm -f $1
  mkfifo $1
  return $?
}

on_start() {
  local readonly log_critical=$LOG_DIR/critical.log
  readonly log_file=$LOG_DIR/$PROJECT.log
  readonly log_pipe=/tmp/$PROJECT@p

  readonly SIZE_UPPER_LIMIT=1024 #Kb
  readonly FILE_UPPER_LIMIT=2000
  readonly CHECK_INTERVAL=200

  readonly image_del_dir=$WORK_DIR/image_del

  main_task || return
  ($DEBUG_MODE) && backup_dir $image_del_dir
  backup_file $log_critical
  backup_file $log_file
  create_pipe $log_pipe || exit 1
}

check_exceed() {
  case $1 in
    size)
      [ $2 -gt $SIZE_UPPER_LIMIT ]
      check_rc && backup $log_file
      ;;
    file)
      [ $2 -gt $FILE_UPPER_LIMIT ]
      check_rc && rm -f $image_del_dir/*
      ;;
  esac
}

backup_dir() {
  is_dir $1 || return
  local bak=$1@backup

  rm -rf $bak
  mv $1 $bak
}

backup_file() {
  is_file $1 || return
  local bak=$1@backup

  #delete old
  rm -f $bak*
  #create new
  mv $1 $bak
  do_gzip $bak
}

run() {
  set -x
  local _l= count=0
  on_start
  ($DEBUG_MODE) || set +x

  while read _l; do
    if [ $((++count)) -eq $CHECK_INTERVAL ]; then
      count=0
      check_exceed size `fsize $log_file`
      ($DEBUG_MODE) && check_exceed file `fcount $image_del_dir`
    fi

    #use double-quote to avoid unfolding
    echo "$_l" >> $log_file
  done<$log_pipe
}

#import with parameter
MAIN_TASK=main

main_task() {
  [ $_1 = $MAIN_TASK ]
  return $?
}

_1=${1-$MAIN_TASK}

case $_1 in
  $MAIN_TASK)
    run;;
esac
