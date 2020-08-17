#!/bin/bash

. ./common.sh

$RUN && set -x

PAGE='https://cmake.org/download/'
PATTERN='https://[^"]*cmake-[^"]+\.tar\.gz'
LOGFILE=$TMP/$0.log

DownloadThenUnpack()
{
  SUFFIX='.tar.gz'
  local html=`CacheHtml`
  URL=`RetrieveUrl $html $PATTERN`
  [ "$URL" ] || return 1
  local f="`basename $URL`"
  { [ -f $f ] && echo ${f%$SUFFIX} && return 0; } || curl -OL $URL &>$LOGFILE || return 2
  tar -zxvf $f &>$LOGFILE || return 3
  echo ${f%$SUFFIX}
}

DumpVersion()
{
  $1 -version
}

CompileThenInstall()
{
  PREFIX=$1/cmake_install
  CMAKE=$PREFIX/bin/cmake
  [ -f $CMAKE ] && DumpVersion $CMAKE && return 0
  mkdir -p $PREFIX
  [ $OPENSSL_ROOT_DIR ] && [ -d $OPENSSL_ROOT_DIR ] || { echo "env OPENSSL_ROOT_DIR not found"; return 1; }
  #export OPENSSL_CRYPTO_LIBRARY=$OPENSSL_ROOT_DIR/lib
  #export OPENSSL_INCLUDE_DIR=$OPENSSL_ROOT_DIR/include
  ./configure --prefix=$PREFIX
  make -j8 && make install && DumpVersion $CMAKE
}

main()
{
  (cd `DownloadThenUnpack` && CompileThenInstall `pwd`)
}
$RUN && main $*
