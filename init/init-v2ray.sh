#!/bin/bash

. ./common.sh

#set -ex

OnInit()
{
  POLOPO_CONFIG='/etc/polipo/config'
  V2RAY_CONFIG='/etc/v2ray/config.json'
  VPS='proxy'
  TMP_DIR='/tmp'
  TEST_URL='ip.gs'
}

InstallV2ray()
{
  test -f $V2RAY_CONFIG || sudo bash ./install-v2ray.sh
  if ! $CheckCmd; then
    $LOG_ERROR "Fail to install V2ray"
    return 1
  fi
}

ConfigV2ray()
{
  local remote_cfg=$TMP_DIR/`basename $V2RAY_CONFIG`
  if ! ssh $VPS "test -f $remote_cfg"; then
    $LOG_ERROR "V2ray config not found"
    return 2
  fi
  scp $VPS:$remote_cfg $TMP_DIR
  sudo mv $V2RAY_CONFIG $V2RAY_CONFIG.bak.$RANDOM
  sudo mv $remote_cfg $V2RAY_CONFIG
  sudo systemctl restart v2ray
}

RetrieveInboundsPort()
{
  local port="`grep -A3 inbounds $V2RAY_CONFIG | grep port`"
  port=${port##* }
  echo ${port%,*}
}

ConfigPolipo()
{
  [ $1 ] || return 3
  local TMP_CONFIG="/tmp/`basename $POLOPO_CONFIG`"
  test -f $POLOPO_CONFIG || sudo apt install -y polipo
  grep -q $1 $POLOPO_CONFIG && return 0
  rm -f $TMP_CONFIG
  cat $POLOPO_CONFIG > $TMP_CONFIG
  cat <<EOF >>$TMP_CONFIG &&
socksParentProxy = localhost:$1
socksProxyType = socks5
EOF
sudo mv $TMP_CONFIG $POLOPO_CONFIG &&
  sudo systemctl restart polipo
}

SetProxy()
{
  case $1 in
    0|enable)
      export http_proxy=localhost:8123
      export https_proxy=$http_proxy;;
    1|disable)
      export -n http_proxy
      export -n https_proxy;;
  esac
}

main()
{
  OnInit
  test -f $V2RAY_CONFIG || InstallV2ray || exit $?
  ConfigV2ray || exit $?
  ConfigPolipo `RetrieveInboundsPort` || exit $?
  $LOG_INFO "Normal Test"
  (SetProxy 1 && curl $TEST_URL)
  $LOG_INFO "Proxy Test"
  (SetProxy 0 && curl $TEST_URL)
  $LOG_SUCCESS "Initialize V2ray Done"
}
main
