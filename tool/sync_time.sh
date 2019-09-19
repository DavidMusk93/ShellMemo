#!/bin/bash

TIME_SERVER_API='http://api.timezonedb.com/v2.1/list-time-zone'
USER_KEY='your-api-key' #limitation, one query per second
TIME_ZONE='Asia/Shanghai'

extract_num() {
  local lp="<$1>"
  local rp="</$1>"
  sed -r "1d;s#.*${lp}([0-9]+)${rp}.*#\1#" $2
}

sync_time() {
  local TMPFILE=/tmp/response
  local timestamp=''
  rm -f $TMPFILE

  wget -q -O $TMPFILE "$TIME_SERVER_API?key=$USER_KEY&zone=$TIME_ZONE"
  seconds=`extract_num timestamp $TMPFILE`
  date -s "@$seconds" &>/dev/null
}

while :; do
  echo "@sync_time `date`"
  sync_time
  sleep 600
done
