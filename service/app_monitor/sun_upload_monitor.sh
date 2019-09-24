#!/bin/sh

PRIORITY=3

. $SUN_WORK_DIR/shell/common.sh

on_start() {
  readonly LOOP_INTERVAL=`expr 1200 + $PRIORITY`
  local readonly output_dir=/database/sun_image

  mkdir -p $WORK_DIR/cache
  mkdir -p $LOG_DIR
  mkdir -p $WORK_DIR/upgrade
  ln -sfn $output_dir $WORK_DIR/image
}

execute() {
  check_empty `pidof $PROJECT` || return 0

  #make sure log-service is up
  launch $SHELL_DIR/sun_log_service.sh $LOG_DIR
  sleep 1

  #launch executable
  export LD_LIBRARY_PATH=$WORK_DIR/lib
  chmod +x $1
  $1 &

  check_pid_bylazy $!
  return $?
}

run() {
  set -x
  on_start
  while :; do
    execute $WORK_DIR/$PROJECT || echo "exec $PROJECT failed"
    do_sleep $LOOP_INTERVAL
  done
}
run
