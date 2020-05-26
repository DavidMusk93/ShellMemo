#!/bin/bash

_init_color_front()
{
  #redf=`tput setaf 1`
  #greenf=`tput setaf 2`
  #bold=`tput bold`
  #reset=`tput sgr0`

  redf='31m';    greenf='32m'
  yellowf='33m'; bluef='34m'
  purplrf='35m'; cyanf='36m'
}

init_log_context()
{
  _init_color_front
}

_color_echo()
{
  echo -e "\033[$1${@:2}\033[0m"
}

log::info()
{
  _color_echo $cyanf $@
}

log::error()
{
  _color_echo $redf $@
}

log::success()
{
  _color_echo $greenf $@
}

fetch_pkg()
{
  curl -OL $1
}

non_empty()
{
  [ "$*" ]
}

check_rc()
{
  return $?
}

truncate_zero()
{
  [ -f $1 ] && echo -n '' > $1
}

append_text()
{
  local f text
  f=$1
  shift
  for text; do
    echo "$text" >> $f
  done
}
