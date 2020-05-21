#!/bin/bash

set -ex

OnInit()
{
  FROM=$1
  TO=$2
}

GitLog()
{
  git log --format=%B -n1 $1 | head -n -3
}

RetrieveCid()
{
  head -n1 $1 | sed -E 's/From ([0-9a-z]+) .*/\1/'
}

main()
{
  test -d $1 && test -d $2 || return 1
  OnInit $1 $2
  for patch in `ls $FROM/*.patch | sort`; do
    cid=`RetrieveCid $patch`
    msg=`(cd $FROM && GitLog $cid)`
    (cd $TO && git apply $patch && git add . && git commit -s -m "$msg")
  done
}
main $*
