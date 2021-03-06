#!/bin/bash

set_value_()
{
  sed -i -E 's#^('$3$2').*#\1'"$4"'#' $1
}

SetValue()
{
  [ $3 ] && [ -f $1 ] || return 1
  local _1 _2
  _1=$1
  _2=$2
  shift 2
  set_value_ $_1 '[[:blank:]]*=[[:blank:]]*' $_2 "$*"
}

#*******************************************************
