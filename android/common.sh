#!/bin/bash

GetRoot()
{
  (cd `dirname $0` && pwd)
}

CheckCmd()
{
  return $?
}

FirstLine()
{
  sed -n '1p;q'
}

AdbPush()
{
  local i d=$1
  shift
  for i; do
    adb push $i $d
  done
}

FilePrintln()
{
  local i f=$1
  shift
  for i; do
    echo "$i" >> $f
  done
}
