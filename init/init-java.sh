#!/bin/bash

download_()
{
  curl --silent -L $1 -o $2
}

CheckCmd()
{
  return $?
}

AssertEmpty()
{
  [ "$1" ] || exit 1
}

DownloadFile()
{
  local f=`basename $1`
  test -f $f || download_ $1 $f
  echo $f
}

ParseDownloadUrl()
{
  local PATTERN='https://[^"]+-x64-linux-jdk.tar.gz'
  egrep -o $PATTERN `DownloadFile $1` | head -n 1
}

RetrivePathFromTar()
{
  local p=`tar -tf $1 | head -n 1`
  echo `basename $p`
}

DownloadAndInstall()
{
  TARGET=/usr/local/jvm
  local url=`ParseDownloadUrl $1` f p
  AssertEmpty $url
  f=`DownloadFile $url`
  AssertEmpty $f
  p=`RetrivePathFromTar $f`
  test -d $TARGET || sudo mkdir -p $TARGET
  test -d $TARGET/$p || sudo tar zxvf $f -C $TARGET
  (cd $TARGET && sudo ln -sfn `basename $TARGET`/$p ../jdk)
}

AppendFile()
{
  local f=$1
  shift
  echo $* >> $f
}

VerifyJdk()
{
  JAVA_HOME=/usr/local/jdk
  CONFIG=config.java
  >$CONFIG
  AppendFile $CONFIG "export JAVA_HOME=$JAVA_HOME"
  AppendFile $CONFIG "export CLASSPATH=\$CLASSPATH:\$JAVA_HOME/lib"
  AppendFile $CONFIG "export PATH=\$PATH:\$JAVA_HOME/bin"
  source $CONFIG
  java -version
}

CleanUp()
{
  mv *.tar.gz /tmp/
  mv *.html /tmp/
  mv *.java /tmp/
}

main()
{
  set -ex
  trap 'CheckCmd && CleanUp' EXIT
  DownloadAndInstall $1
  VerifyJdk
}
main https://docs.aws.amazon.com/corretto/latest/corretto-11-ug/downloads-list.html
