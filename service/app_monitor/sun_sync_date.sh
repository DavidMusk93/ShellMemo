#!/bin/sh

PRIORITY=1

. $SUN_WORK_DIR/shell/common.sh

TIME_SERVER_API='http://api.timezonedb.com/v2.1/list-time-zone'
USER_KEY='your-api-key' #limitation, one query per second
TIME_ZONE='Asia/Shanghai'

extract_num() {
  local lp="<$1>"
  local rp="</$1>"
  sed -r "1d;s#.*${lp}([0-9]+)${rp}.*#\1#" $2
}

check_rc() {
  return $?
}

sync_time() {
  local TMPFILE=/tmp/response@sync_time
  local timestamp=''
  rm -f $TMPFILE

  wget -q -O $TMPFILE "$TIME_SERVER_API?key=$USER_KEY&zone=$TIME_ZONE"
  check_rc || return 1
  seconds=`extract_num timestamp $TMPFILE`
  date -s "@$seconds" &>/dev/null
  return $?
}

on_start() {
  readonly LOOP_INTERVAL=`expr 2 \* 60 \* 60 + $PRIORITY`
}

run() {
  on_start

  while :; do
    echo "@sync_time `date`"
    sync_time || echo "@sync_time error occurred"
    do_sleep $LOOP_INTERVAL #a lightweight service
  done
}
run
