#!/bin/bash

set -ex

__pwd()
{
  (cd `dirname $0` && pwd)
}

CreateService()
{
  cat <<EOF >$1 &&
[Unit]
Description=Keep Connection Even Outside
After=network.target time-sync.target

[Service]
Type=simple
User=$2
ExecStart=$3 check-remote-port
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
sudo mv $1 $SYSTEMD_DIR
}

CreateTimer()
{
  cat <<EOF >$1 &&
[Unit]
Description=Check Remote Port

[Timer]
OnBootSec=1min
OnUnitActiveSec=${2}min
RandomizedDelaySec=5min
Persistent=true

[Install]
WantedBy=multi-user.target
EOF
sudo mv $1 $SYSTEMD_DIR
#(test -f $SYSTEMD_DIR/$1 || { cd $SYSTEMD_DIR; sudo ln -sfn $__PWD/$1; })
}

OnInit()
{
  SYSTEMD_DIR=/etc/systemd/system
  __PWD=`__pwd`
  SELF=`basename $0`
  NAME=${SELF%.*}
  REMOTE_HOST=tx
  REMOTE_PORT=7788
  LOCAL_PORT=`RetrieveLocalPort`
  [ $LOCAL_PORT ] || LOCAL_PORT=22
  PID_FILE=/tmp/$NAME.pid
  LOG_FILE=/tmp/$NAME.log
  chmod +x $0
}

KillProcess()
{
  local pid=$1
  test -f $1 && pid=`cat $1`
  [ $pid ] || return 1
  kill -0 $pid &>/dev/null && kill -9 $pid
}

CheckRemotePort()
{
  ssh $1 "nc -zv localhost $2"
}

RetrieveLocalPort()
{
  sed -E -n 's/^[#]?Port[[:blank:]]+([0-9]+)/\1/p' ${1:-/etc/ssh/sshd_config}
}

StartTunnel()
{
  nohup ssh -v -NCR $2:localhost:$3 $1 &>$LOG_FILE &
  echo $! > $PID_FILE
}

CheckTunnelProcess()
{
  ps aux | grep -v grep | grep -q $1
}

main()
{
  OnInit
  case $1 in
    0|bootstrap)
      CreateService ${2:-$NAME}.service $USER $__PWD/$SELF
      CreateTimer ${2:-$NAME}.timer 1
      ;;
    1|check-remote-port)
      if CheckTunnelProcess $REMOTE_PORT; then
        CheckRemotePort $REMOTE_HOST $REMOTE_PORT || { KillProcess $PID_FILE; rm -f $PID_FILE; }
      else
        StartTunnel $REMOTE_HOST $REMOTE_PORT $LOCAL_PORT
      fi
      ;;
  esac
}
main $*
