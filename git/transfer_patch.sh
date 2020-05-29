#!/bin/bash

set -ex

CleanUp()
{
  (cd $FROM && rm -f *.patch)
}

OnSuccess()
{
  CleanUp
  pushd $TO
  cmd="$PUSH_CMD"
  if [ "$cmd" ]; then
    read -p "$PUSH_CMD? (y/n, default n)" y
    if [ $y = 'y' ] || [ $y = 'Y' ]; then
      eval "$cmd"
    fi
  fi
  popd
}

OnInit()
{
  FROM=$1
  TO=$2
  trap '[ $? -eq 0 ] && OnSuccess || CleanUp' EXIT SIGINT
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
  (cd $FROM && git format-patch $3) || return $?
  for patch in `ls $FROM/*.patch | sort`; do
    cid=`RetrieveCid $patch`
    msg=`(cd $FROM && GitLog $cid)`
    (cd $TO && git apply $patch && git add . && git commit -s -m "$msg")
  done
}
main $*
