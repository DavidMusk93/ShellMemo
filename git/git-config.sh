#!/bin/bash

git_config_()
{
  local _1=$1 _2=$2
  shift 2
  git config --global $_1.$_2 "$*"
}

GitUserConfig()
{
  git_config_ user $*
}

GitCoreConfig()
{
  git_config_ core $*
}

GitAliasConfig()
{
  git_config_ alias $*
}

main()
{
  GitUserConfig email davidmusksun1993@gmail.com
  GitUserConfig name Mingqiang Sun
  GitCoreConfig editor vim
  GitAliasConfig co checkout
  GitAliasConfig br branch
  GitAliasConfig ci commit
  GitAliasConfig st status
}
set -x
main $*
