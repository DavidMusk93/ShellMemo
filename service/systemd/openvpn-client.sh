#!/bin/bash

set -ex

LoadEnv()
{
  for i; do eval "$i=\$ENV_$i"; done
}

EndsWith()
{
  case "$1" in
    *"$2") return 0;;
    *)     return 1;;
  esac
}

OnInit()
{
  _pwd() { (cd `dirname $0` && pwd); }
  WORK_DIR=`_pwd`
  OPENVPN_HOME=/etc/openvpn
  SELF="$WORK_DIR/`basename $0`"
  TMP_SERVICE='/tmp/openvpn.service'
  TARGET_SERVICE='/lib/systemd/system/openvpn.service'
  chmod +x $SELF
  CONFIG_SUFFIX='.ovpn'
  LoadEnv VPS REMOTE_DIR CONFIG
  EndsWith $CONFIG $CONFIG_SUFFIX || CONFIG=$CONFIG$CONFIG_SUFFIX
}

LoadConfig()
{
  [ "$VPS" ] && [ "$REMOTE_DIR" ] && [ "$CONFIG" ] || exit $?
  scp $VPS:$REMOTE_DIR/$CONFIG /tmp/ || exit $?
  sudo mv /tmp/$CONFIG $OPENVPN_HOME
}

CreateService()
{
  cat <<EOF >$TMP_SERVICE &&
[Unit]
Description=OpenVPN service
After=network.target

[Service]
Type=simple
Environment="CONFIG=$OPENVPN_HOME/$CONFIG"
ExecStart=/usr/sbin/openvpn --config "\$CONFIG"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo cp $TMP_SERVICE $TARGET_SERVICE &&
  sudo systemctl daemon-reload && sudo systemctl start openvpn.service
}

main()
{
  case $1 in
    bootstrap)
      OnInit
      LoadConfig
      CreateService;;
    test)
      # systemd environment has exported to subprocess
      echo $TEST;;
  esac
}
main $*
