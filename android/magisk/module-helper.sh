#!/system/bin/sh

OnInit()
{
  MAGISK_SERVICE=/data/adb/service.d
}

Copy()
{
  cp $1 $MAGISK_SERVICE
  chmod 777 $MAGISK_SERVICE/`basename $1`
}

main()
{
  set -x
  OnInit
  Copy $*
}
main $*
