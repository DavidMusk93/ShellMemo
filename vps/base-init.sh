#!/bin/bash

. common.sh

#*******************************************************

ModifyHostname()
{
  local f=/etc/hosts
  BackupFile $f
  SetSpaceValue $f `GetIp` $1
  f=/etc/hostname
  BackupFile $f
  echo $1 > $f
  command -v hostnamectl && hostnamectl set-hostname $1
}

ModifySshPort()
{
  SetSpaceValue /etc/ssh/sshd_config Port $1
}

OnInit()
{
  MY_SSH_FORWARD_PORT=26152
  MY_HOSTNAME=racknerd
}

#*******************************************************

main()
{
  set -x
  IsRoot || Abort 'Root is Required!'
  OnInit
  ModifyHostname $MY_HOSTNAME
  ModifySshPort $MY_SSH_FORWARD_PORT
}
main $*
