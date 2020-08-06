#!/bin/bash

. ./common.sh

set -x

PAGE='https://cmake.org/download/'
PATTERN='https://[^"]*cmake-[^"]+\.tar\.gz'

DownloadThenUnpack()
{
  SUFFIX='.tar.gz'
  local html=`CacheHtml`
  URL=`RetrieveUrl $html $PATTERN`
  [ "$URL" ] || return 1
  local f="`basename $URL`"
  { [ -f $f ] && echo ${f%$SUFFIX} && return 0; } || curl -OL $URL || return 2
  tar -zxvf $f || return 3
  echo ${f%$SUFFIX}
}

DumpVersion()
{
  $1 -version
}

CompileThenInstall()
{
  cd $1
  PREFIX="`pwd`/cmake_install"
  CMAKE=$PREFIX/bin/cmake
  [ -f $CMAKE ] && DumpVersion $CMAKE && return 0
  mkdir -p $PREFIX
  [ $OPENSSL_ROOT_DIR ] && [ -d $OPENSSL_ROOT_DIR ] || { echo "miss OPENSSL_ROOT_DIR"; return 1; }
  export OPENSSL_CRYPTO_LIBRARY=$OPENSSL_ROOT_DIR/lib
  export OPENSSL_INCLUDE_DIR=$OPENSSL_ROOT_DIR/include
  ./configure --prefix=$PREFIX
  make -j8 && make install && DumpVersion $CMAKE
}

main()
{
  path="`DownloadThenUnpack`"
  [ "$path" ] && CompileThenInstall $path
}
main $*
