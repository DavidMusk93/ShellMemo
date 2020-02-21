#!/system/bin/sh

alias ll='ls -al'

MAGISK_TMP=/sbin/.magisk
SECURE_DIR=/data/adb

MODULE_MNT=$magisk_tmp/modules
MODULE_ROOT=$secure_dir/modules

variables=(MAGISK_TMP SECURE_DIR MODULE_MNT MODULE_ROOT)

SHELL_PATH=$PATH
export PATH=$MAGISK_TMP/busybox:$PATH

utility::is_zero()
{
  [ $1 -eq 0 ]
  return $?
}

isZero()
{
  return $1
}

show()
{
  local _1=${1-magisk}
  shift
  case $_1 in
    magisk)
      local dir var
      case $1 in
        0)
          # List essencial Magisk variables
          for var in ${variables[@]}; do
            eval "printf '%-12s %s\n' $var \$$var"
          done
          ;;
        1|tmp)
          dir=$MAGISK_TMP;;
        2|secure)
          dir=$SECURE_DIR;;
      esac
      utility::is_zero $1 && return
      [ $2 ] && dir+=/$2
      set -x
      # List specific Magisk directory
      ls -al $dir
      set +x
      ;;
    package)
      case $1 in
        0|list)
          # https://gist.github.com/davidnunez/1404789
          pm list packages -f | sed -e 's/.*=//' | sort;;
        1|detail)
          dumpsys package $2;;
      esac
      ;;
  esac
}

# Fast commands to list Package & Permission
_cmd()
{
  case ${1-0} in
    0|package)
      cmd package list packages ${2-'-3'} | sed -e 's/.*://';;
    1|permissions)
      cmd package list permissions ${2-'-g'};;
  esac
}

# Inspired by Magisk Shortcuts
_am()
{
  case ${1-0} in
    0|start)
      # -es is different with -e
      am start -n com.topjohnwu.magisk/a.c -a android.intent.action.VIEW -f 0X10008000 -e section ${2-magiskhide};;
  esac
}

# Elegant way to export PATH / LD_LIBRARY_PATH
env_export()
{
  # Input check
  [ ! $2 ] || [ ! -d $2 ] && return 1
  local all flag
  flag=(false false false)
  # All uppercase
  case $1 in
    0|PATH)
      flag[0]=true
      all=$PATH;;
    1|LD_LIBRARY_PATH)
      flag[1]=true
      all=$LD_LIBRARY_PATH;;
    2|CLASSPATH)
      flag[2]=true
      all=$CLASSPATH;;
    *)
      return 1;;
  esac
  if ! echo $all | grep -q $2; then
    # Try to remove leading ':'
    all=${all#:}
    all+=:$2
    ${flag[0]} && export PATH=$all
    ${flag[1]} && export LD_LIBRARY_PATH=$all
    ${flag[2]} && export CLASSPATH=$all
  fi
  return 0
}

_settings()
{
  case $1 in
    list)
      # List settings namespace
      settings list $2;;
    0|location_get)
      # Check current location providers
      settings get secure location_providers_allowed;;
    1|location_put)
      # Set location provider:
      #  -gps
      #  +gps
      #  -network
      #  +network
      settings put secure location_providers_allowed $2;;
    2|disable_auto)
      # Disable automatically download & install upload package
      settings put secure auto_download 0
      settings put secure auto_update 0;;
  esac
}

is_zero()
{
  [ $1 -eq 0 ]
  return $?
}

package_check()
{
  # Input check
  [ $1 ] || return 1
  local i
  # Make sure $1 is a valid package
  for i in `_cmd`; do
    [ $1 = $i ]
    is_zero $? && return 0
  done
  return 1
}

_adb()
{
  local KEY=service.adb.tcp.port PORT=5555
  case ${1-0} in
    0|check.tcp.port)
      getprop $KEY;;
    1|enable.tcp.port)
      setprop $KEY $PORT
      stop adbd
      start adbd;;
  esac
}

_grant()
{
  package_check $3 || return 1
  # Permission group for location
  LOCATION_PERMISSION=(android.permission.ACCESS_FINE_LOCATION android.permission.ACCESS_COARSE_LOCATION)
  # Simple wrapper for pm
  __pm()
  {
    local permission
    for permission in ${LOCATION_PERMISSION[@]}; do
      pm $1 $2 $permission
    done
  }

  case $1 in
    0|location)
      case $2 in
        grant|revoke) __pm $2 $3;;
      esac
      ;;
  esac
  return $?
}

ends_with()
{
  case "$1" in
    *"$2") return 0;;
  esac
  return 1
}

_getprop()
{
  PROP=/system/build.prop
  case ${2-0} in
    0|ro.build.version.sdk)
      sed -n 's/ro.build.version.sdk=//p' $PROP;;
    *)
      exit 1;;
  esac
}

update_module()
{
  local c
  case `_getprop` in
    24)
      XPOSED_MOUDLE_LIST=/data/user_de/0/de.robv.android.xposed.installer/conf/modules.list;;
    27)
      XPOSED_MOUDLE_LIST=/data/user_de/0/org.meowcat.edxposed.manager/conf/modules.list;;
  esac
  TARGET_PACKAGE=com.example.xposedtest

  case $1 in
    0|auto)
      set -x
      pm install -r -t /sdcard/app-debug.apk
      ls /data/app/$TARGET_PACKAGE*/base.apk > $XPOSED_MOUDLE_LIST
      reboot
      ;;
    1|normal)
      set -x
      pm install -r -t /sdcard/app-debug.apk
      set +x
      return
      ;;
  esac

  # Install test apk (/sdcard vs. /sdcard/)
  select apk in `find /sdcard/ -maxdepth 1 -name "*.apk"`; do
    if ends_with $apk app-debug.apk; then
      pm install -r -t $apk
      break
    fi
  done
  # Update xposed modules.list
  ls /data/app/$TARGET_PACKAGE*/base.apk > $XPOSED_MOUDLE_LIST

  echo -n "Reboot?"
  # Auto reboot if no input within 5 seconds
  # timeout 5s read c

  read c
  [ ! $c ] || [ $c = 'Y' ] || [ $c = 'y' ] && reboot
}

_log()
{
  case ${1-0} in
    0) logcat | grep @sun;;
    1) logcat | grep Xposed;;
  esac
}

debugLog()
{
  tail -f /data/local/tmp/debug.log
}

installDebugApk()
{
  isZero `id -u` || return
  set -x
  pm install -r -t /sdcard/app-debug.apk
  case ${1-0} in
    0|xposedtest)
      am start -n com.example.xposedtest/.MainActivity
      sleep 5
      reboot;;
  esac
  set +x
}

TopActivity()
{
  dumpsys window | grep "mCurrentFocus"
}

execSql()
{
  magisk --sqlite "insert into policies (uid,package_name,policy,until,logging,notification) values(10155,'com.example.xposedtest',2,0,0,0)"
}

CheckCmd()
{
  return $?
}

SafeKill()
{
  local p
  test -d /proc/$1 && p=$1 || p=`pidof $1`
  [ $p ]  && kill -0 $p && kill -9 $p
}

DumpPackage()
{
  dumpsys package $1
}

Timestamp()
{
  date +"%m/%d %H:%M:%S"
}

ExplicitExecute()
{
  echo "[`Timestamp`] $*"
  eval $*
}

FindAndCopyPackage()
{
  OUT=/sdcard/
  local p
  p=`DumpPackage $1 | grep path:`
  p=${p##* }
  p=`dirname $p`
  ExplicitExecute "cp -r $p $OUT"
  echo "adb pull $OUT`basename $p`"
}

SSH_DIR=/data/xm
env_export 0 $SSH_DIR/bin
env_export 1 $SSH_DIR/lib64

[ $1 ] && debugLog
