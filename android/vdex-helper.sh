#!/bin/bash

Ln()
{
  ln -sfn $1 $2
}

Conveter()
{
  EXTRACTOR=~/github/vdexExtractor/bin/vdexExtractor
  $EXTRACTOR -i $1.vdex
}

Pack()
{
  TARGET=classes.dex
  Ln $1_$TARGET $TARGET
  zip $1.apk $TARGET
}

main()
{
  [ $1 ] && [ -d $1 ] || exit 1
  local p=`basename $1`
  [ $2 ] && p=$2
  cd $1
  Ln `find . -name "*.vdex"`
  Conveter $p && Pack $p
}
set -x
main $*
