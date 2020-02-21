#!/bin/bash

. common.sh

#*******************************************************

GetCertText()
{
  dump_text_() {
    openssl x509 -text -inform $1 -in $2
  }
  m1_() {
    dump_text_ PEM $1
  }
  m2_() {
    dump_text_ DER $1
  }
  m1_ $1 2>/dev/null || m2_ $1
}

GetCertHash()
{
  GetCertText $1 | openssl x509 -subject_hash_old
}

RenameThenPushCert()
{
  declare -g cert
  cert=`GetCertHash $1 | FirstLine`.0
  (cd `dirname $1` && cp -f $1 $cert && AdbPush $TEMP $cert)
}

Clean()
{
  rm -f $SCRIPT
}

OnInit()
{
  MAGISK_MODULE=/data/adb/modules
  MODULE_NAME=fiddler-cert
  SYS_CACERTS=/system/etc/security/cacerts
  TEMP=/sdcard/
  PROP=module.prop
  SCRIPT=fiddler-helper.sh
  CONFIG_HELPER=config-helper.sh
  Clean
  trap 'Clean' EXIT
}

#*******************************************************

main()
{
  OnInit
  RenameThenPushCert $1
  FilePrintln $SCRIPT \
    '#!/system/bin/sh' \
    '' \
    'Abort()' \
    '{' \
    '  echo $*' \
    '  exit 1' \
    '}' \
    '' \
    ". $TEMP$CONFIG_HELPER" \
    '' \
    'set -x' \
    '[ `id -u` -eq 0 ] || Abort "Root is required!"' \
    "cert=$TEMP$cert" \
    "dst=$MAGISK_MODULE/$MODULE_NAME$SYS_CACERTS" \
    'mkdir -p $dst' \
    '[ -f $cert ] || Abort "$cert not found!"' \
    'cp -f $cert $dst' \
    'chmod 644 $dst/*' \
    'set +x' \
    '' \
    "prop=$MAGISK_MODULE/$MODULE_NAME/$PROP" \
    "for i in $MAGISK_MODULE/*/$PROP; do [ \$i = \$prop ] || cp \$i \$prop; break; done" \
    'SetValue $prop id          fiddler-cert' \
    'SetValue $prop name        Fiddler Certification' \
    'SetValue $prop version     v0.1' \
    'SetValue $prop versionCode 100' \
    'SetValue $prop author      sun' \
    'SetValue $prop description VPN concerned.'
  AdbPush $TEMP $SCRIPT $CONFIG_HELPER
}
main $*
