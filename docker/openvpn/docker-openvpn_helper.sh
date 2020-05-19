#!/bin/bash

set -x

function __pwd() {
  (cd `dirname $0` && pwd)
}

function retrieve_cid() {
  local cid=`docker ps | grep $1`
  echo ${cid%% *}
}

function sed_uncomment() {
  sudo cp $3 $3.bak
  sudo sed -E -i 's/^['$1']?('$2'.*)/\1/' $3
  sudo sysctl -p
}

#-------------------------------------------------------

function on_init() {
  OVPN_DATA=`__pwd`/ovpn-data-tx
  DOCKER_IMAGE=kylemanna/openvpn
}
on_init

case $1 in
  0|start)
    docker run -v $OVPN_DATA:/etc/openvpn -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn;;
  1|stop)
    docker stop `retrieve_cid $DOCKER_IMAGE`;;
  2|new)
    docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn easyrsa build-client-full $2 nopass
    docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_getclient $2 > $2.ovpn;;
  3|bootstrap)
    docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_genconfig -u udp://tencent.guohuasun.com -c -d -D -z -s "10.0.0.0/24"
    docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn ovpn_initpki;;
  4|network-config)
    sed_uncomment '#' net.ipv4.ip_forward /etc/sysctl.conf;;
esac

#-------------------------------------------------------

#@ref
# https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-18-04
