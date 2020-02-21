#!/bin/bash

. common.sh

InitAndroidEnv()
{
  MAGISK_MODULE=/data/adb/modules
  TEMP=/sdcard/
}

#*******************************************************

Clean()
{
  rm -f hosts
  rm -f $MODULE_HELPER
}

OnInit()
{
  declare -g -A CONFIG
  KEY=(id name version versionCode author description)
  MODULE=my-hosts
  CONFIG[id]=$MODULE
  CONFIG[name]="User defined hosts"
  CONFIG[version]=v0.1
  CONFIG[versionCode]=100
  CONFIG[author]=sun
  CONFIG[description]="Truncate url as you wish."
  PROP=module.prop
  MODULE_HELPER=hosts-helper.sh
  SYSTEM_HOST=/system/etc
  InitAndroidEnv
  trap 'Clean' EXIT
}

cat > hosts << 'EOF'
127.0.0.1       localhost
::1             ip6-localhost
127.0.0.1       update.miui.com
127.0.0.1       update.intl.miui.com
127.0.0.1       hugeota.d.miui.com
EOF

GenerateModule()
{
  local i d=${CONFIG[id]}
  rm -rf $d/*
  mkdir -p $d$SYSTEM_HOST
  mv hosts $d$SYSTEM_HOST
  pushd $d &>/dev/null
  for i in ${KEY[@]}; do
    echo "$i=${CONFIG[$i]}" >> $PROP
  done
  popd &>/dev/null
}

PushModule()
{
  rm -f $MODULE_HELPER
  FilePrintln $MODULE_HELPER \
    '#!/system/bin/sh' \
    '' \
    'set -x' \
    "rm -rf $MAGISK_MODULE/$MODULE" \
    "cp -r $TEMP$MODULE $MAGISK_MODULE" \
    "chmod 644 $MAGISK_MODULE/$MODULE/$PROP" \
    "chmod 644 $MAGISK_MODULE/$MODULE/*/*/hosts" \
    'set +x'
  AdbPush $TEMP $MODULE_HELPER $MODULE
}

#*******************************************************

main()
{
  OnInit
  GenerateModule
  PushModule
}
main $*
