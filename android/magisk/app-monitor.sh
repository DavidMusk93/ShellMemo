#!/system/bin/sh

CheckCmd()
{
  return $?
}

OnInit()
{
  MAIN_PACKAGE_NAME=com.example.xposedtest
  TEMP=/data/local/tmp
  TAG='not exist'
  DEFAULT_APK='/sdcard/app-debug.apk'
}

LogInfo()
{
  echo "`date` $$ $*"
}

ExplicitExec()
{
  LogInfo EXEC: $*
  eval "$*"
}

OnMainAppAlive()
{
  LogInfo $1 is alive!
}

OnMainAppDead()
{
  LogInfo $1 is dead, launch it directly.
  ExplicitExec am start -n $1/.MainActivity | grep -q $TAG && OnAppNotExist
}

OnAppNotExist()
{
  if [ -f $DEFAULT_APK ]; then
    ExplicitExec pm install -r -t $DEFAULT_APK
    return $?
  fi
  LogInfo $DEFAULT_APK not exist!
  return 1
}

CheckMainActivity()
{
  pidof $1
  CheckCmd && OnMainAppAlive $1 || OnMainAppDead $1
}

MainLoop()
{
  local i=0
  while true; do
    sleep 120
    LogInfo ROUND $((++i))
    CheckMainActivity $MAIN_PACKAGE_NAME
  done
}

main()
{
  OnInit
  MainLoop &>$TEMP/app-monitor.log &
}
main $*
