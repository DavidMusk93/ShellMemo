#!/bin/bash

. ./common.sh

set -ex

PAGE='https://www.openssl.org/source/'
PATTERN='https://[^"]*openssl-1.[0-9]{1,2}.[0-9]{1,2}[[:alpha:]]*\.tar\.gz'

DownloadThenUnpack()
{
  SUFFIX='.tar.gz'
  local html="`CacheHtml`"
  URL="`RetrieveUrl $html $PATTERN`"
  [ "$URL" ] || { URL="`RetrieveUrl $html ${PATTERN:13}`"; [ "$URL" ] && URL=$PAGE$URL || return 1; }
  local f=`basename $URL`
  { [ -f $f ] && echo ${f%$SUFFIX} && return 0; } || { curl -OL $URL && tar -zxvf $f &>$f.log; }
  echo ${f%$SUFFIX}
}

DumpVersion()
{
  export LD_LIBRARY_PATH=`dirname $1`/lib:$LD_LIBRARY_PATH
  $1 <<EOF
version
exit
EOF
}

CompileThenInstall()
{
  cd $1
  PREFIX=`pwd`/openssl_install
  OPENSSL=$PREFIX/bin/openssl
  [ -f $OPENSSL ] && { DumpVersion $OPENSSL; return 0; }
  mkdir -p $PREFIX
  ./config --prefix=$PREFIX --openssldir=$PREFIX
  make -j8 && make install && DumpVersion  $OPENSSL
}

main()
{
  path=`DownloadThenUnpack`
  [ $path ] && CompileThenInstall $path
}
main $*
