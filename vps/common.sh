#!/bin/bash

Trim()
{
  echo -n $*
}

IsRoot()
{
  [ $EUID ] && return $EUID
  return `id -u`
}

Abort()
{
  echo $*
  exit 1
}

set_value_()
{
  sed -i -E "s#^($3$2).*#\1$4#" $1
}

SetEqualValue()
{
  local _1 _2
  _1=$1 _2=$2
  shift 2
  set_value_ $_1 '[[:blank:]]*=[[:blank:]]*' $_2 "$*"
}

SetSpaceValue()
{
  set_value_ $1 '[[:blank:]]+' $2 $3
}

BackupFile()
{
  [ -f $1 ] && cp $1 ${2-$1.bak}
}

GetIp()
{
  local ip=`hostname -I`
  echo ${ip%% *}
}
