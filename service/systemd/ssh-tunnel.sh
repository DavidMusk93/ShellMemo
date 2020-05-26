#!/bin/bash

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

[Install]
WantedBy=multi-user.target
EOF
(cd $SYSTEMD_DIR && sudo ln -sfn $__PWD/$1)
}

CreateTimer()
{
  cat <<EOF >$1 &&
[Unit]
Description=Check Remote Port

[Timer]
OnCalendar=${2}min
RandomizedDelaySec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF
(cd $SYSTEMD_DIR && sudo ln -sfn $__PWD/$1)
}

OnInit()
{
  SYSTEMD_DIR=/etc/systemd/system
  __PWD=`__pwd`
  SELF=`basename $0`
  NAME=${SELF%.*}
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
      echo `date` >>/tmp/trivial@test;;
  esac
}
main $*
