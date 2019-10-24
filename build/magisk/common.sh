#!/bin/bash

check_rc()
{
  return $?
}

trim()
{
  echo -n $*
}

close_fd()
{
  eval "exec $1>&-"
}

extract_link()
{
  local REGEX='s/build_(x[0-9]{1}).sh/\1/p'
  GRADLE=./gradlew
  WORK_DIR=`basename $0 | sed -n -E $REGEX`
  [ -d $WORK_DIR ] || exit 1

  cd $WORK_DIR
  if [ -f $GRADLE ]; then
    [ -x $GRADLE ] || chmod +x $GRADLE
    export ANDROID_SDK_ROOT=~/Android/Sdk
  fi
}

abort()
{
  echo $*
  exit 1
}

lock()
{
  LOCKED=false
  FD_LOCK=$1
  flock -w .5 -x $FD_LOCK && LOCKED=true
  $LOCKED
  return $?
}

unlock()
{
  ${LOCKED:-false} && flock -u $FD_LOCK
}
