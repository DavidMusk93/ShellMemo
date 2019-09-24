#!/bin/sh

PRIORITY=0

. $SUN_WORK_DIR/shell/common.sh

on_start() {
  local readonly script_dir=$WORK_DIR/shell
  local i=0 script=

  main_task || return
  mkdir -p $LOG_DIR
  rm -f $LOG_DIR/*.pid

  do_inject

  launch $script_dir/debug.sh $LOG_DIR

  for script in `ls $script_dir/*.sh`; do
    check_priority $script || echo "ignore $script"
  done

  #jump bootstrap
  while [ $((++i)) -lt 8 ]; do
    script=`eval "echo \\$_p$i"`
    check_empty $script || launch $script $LOG_DIR
  done

  mount_nfs || exit 1
}

readonly inject_content=/tmp/$PROJECT@inject

cat > $inject_content << EOF
alias ll='ls -al'

export SUN_WORK_DIR=$WORK_DIR
export SUN_LOG_DIR=\$SUN_WORK_DIR/log

lcheck() {
  case \$1 in
    bootstrap)
      tail -f \$SUN_LOG_DIR/bootstrap@sh.log;;
    ntp)
      tail -f \$SUN_LOG_DIR/sun_sync_date@sh.log;;
    log)
      tail -f \$SUN_LOG_DIR/sun_log_service@sh.log;;
    monitor)
      tail -f \$SUN_LOG_DIR/sun_upload_monitor@sh.log;;
    upgrade)
      tail -f \$SUN_LOG_DIR/sun_upgrade_service@sh.log;;
  esac
}
EOF

do_inject() {
  local user_cfg=/etc/profile
  grep ll $user_cfg || cat $inject_content >> $user_cfg
}

ping_check() {
  local timeout=${2-5}
  ping -c 3 -w $timeout $1
  return $?
}

wait_ping() {
  local retry=${2-5}
  local i=0
  while [ $((i++)) -lt $retry ]; do
    ping_check $1 && return 0
  done
  return 1
}

on_mount_success() {
  local ssh_script=/mnt/arm_ssh/enable_arm_openssh.sh
  [ -e $ssh_script ] && sh $ssh_script
  return 0
}

mount_nfs() {
  local nfs_ip=192.168.10.56
  local nfs_path=/home/david/nfs/ip_252
  local mount_target=/mnt

  df | grep /mnt && return 0
  wait_ping $nfs_ip || return 1
  mount -t nfs -o nolock $nfs_ip:$nfs_path $mount_target
  check_rc && on_mount_success || return 1
  return 0
}

MAIN_TASK=main

run() {
  set -x
  case $1 in
    $MAIN_TASK)
      on_start
      ;;
    clean)
      local pid=
      for f in `ls $LOG_DIR/*.pid`; do
        pid=`pcontent $f`
        check_pid $pid && kill -SIGUSR1 $pid
        check_rc && kill -9 $pid
      done
      ;;
  esac
}

main_task() {
  [ $_1 = $MAIN_TASK ]
  return $?
}

_1=${1-$MAIN_TASK}
run $_1
