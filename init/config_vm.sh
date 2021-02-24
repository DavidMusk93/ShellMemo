#!/bin/bash

sun::vm::ip_cfg() {
    IPNUM='[0-9]{1,3}'
    IPREGEX="$IPNUM\.$IPNUM\.$IPNUM\.$IPNUM"
    IP=$1
    __static_cfg() {
        echo $IP | egrep -q $IPREGEX || return 1
        CFGDIR=/etc/sysconfig/network-scripts
        DEFAULTIF=ens33
        DEFAULTNETMASK=23
        DEFAULTGATEWAYSUFFIX=1
        DEFAULTDNS1=10.10.10.4
        DEFAULTDNS2=233.5.5.5
        (
            set -e
            cd $CFGDIR
            IFCFG=ifcfg-$DEFAULTIF
            test -f $IFCFG && {
                . $IFCFG
                mv $IFCFG $IFCFG.0
                cat >$IFCFG <<eof
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=$NAME
UUID=$UUID
ONBOOT=yes
IPADDR=$IP
GATEWAY=${IP%.*}.$DEFAULTGATEWAYSUFFIX
PREFIX=$DEFAULTNETMASK
DNS1=$DEFAULTDNS1
DNS2=$DEFAULTDNS2
eof
                systemctl restart network
            }
        )
    }
    __static_cfg
}
