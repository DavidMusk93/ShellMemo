#!/bin/sh

PRIORITY=5

. $SUN_WORK_DIR/shell/common.sh

on_success() {
  do_sleep $LOOP_INTERVAL
  return 0
}

on_failure() {
  kill -9 $1
  eval $2
  sleep 10
  return 0
}

check_ssh() {
  local i=0 retry=10

  while [ $((i++)) -lt $retry ]; do
    check_empty `pidof ssh` && sleep 60 || return 0
  done
  echo "ssh has not found"
  return 1
}

on_start() {
  readonly LOOP_INTERVAL=`expr 600 + $PRIORITY`

  check_ssh
  assert_rc
}

run() {
  on_start

  local pid= cmd= ls= rs= forward_port= check_cmd=
  #infinite loop
  while :; do
    pid=`pidof ssh`
    if check_empty $pid; then
      [ $cmd ] && $cmd
      sleep 2
      pid=`pidof ssh`
      assert_empty $pid
    fi

    if check_empty $check_cmd; then
      cmd=`cat /proc/$pid/cmdline | tr '\x0' ' '`
      cmd=`trim $cmd`

      ls=${cmd%-f*}
      ls=`trim $ls`

      rs=${cmd#*-i}
      rs=`trim $rs`

      forward_port=${cmd%%:*}
      forward_port=${forward_port##* }

      check_cmd="$ls -i $rs 'nc -zv localhost $forward_port'"
      assert_empty $check_cmd
    fi

    eval $check_cmd
    check_rc && on_success || on_failure "$pid" "$cmd"
  done
}
run
