#!/bin/bash

TrySource()
{
  test -f $1 && . $1
}
export TrySource

SetProxy()
{
  case ${1:-'enable'} in
    0|enable)
      case ${2:-'v2ray'} in
        v2ray-linux) export http_proxy=localhost:8123;;
        v2ray-win) export http_proxy=localhost:2081;;
        trojan) export http_proxy=localhost:2091;;
        *)      return 1;;
      esac
      export https_proxy=$http_proxy
      ;;
    1|disable)
      export -n http_proxy
      export -n https_proxy
      ;;
  esac
}
