#!/system/bin/sh

SetTcpPort()
{
  setprop service.adb.tcp.port 5555
  stop adbd && start adbd
}

FilterLogcat()
{
  LOG=/data/local/tmp/debug.log
  rm -f $LOG
  logcat -f $LOG *:S @sun:V EdXposed-Bridge:V &
}

main()
{
  SetTcpPort
  FilterLogcat
}
main
