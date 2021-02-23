#!/bin/bash

sun::on_begin() {
    WORKDIR=/opt/cloudera
}

sun::nfs_copy() {
    FROM=/opt/nfs/hadoopSW/cloudera
    TO=$WORKDIR
    VERSION=5.16.2
    __on_success() {
        createrepo .
    }
    __on_begin() {
        REALTO=$TO
        #avoid deleting by UNINSTALLER
        TO=.$RANDOM.cm.$VERSION
        mkdir -p $TO
    }
    __on_end() {
        ln -sfn $TO $REALTO
    }
    __copy() {
        rsync --progress -avr $FROM/$1 $TO
        (
            set -e
            cd $TO
            DIR=$(dirname $1)
            BASE=$(basename $1)
            mkdir -p $DIR
            mv $BASE $DIR
            __on_success
        )
    }
    __on_begin
    #__copy "dependencies/centos/x86_64/7"
    #__copy "cdh5/parcel/$VERSION"
    __copy "cm5/centos/x86_64/7/$VERSION"
    __on_end
}

sun::base_cfg() {
    __time_cfg() {
        timedatectl set-local-rtc 1
        timedatectl set-timezone Asia/Shanghai
        timedatectl set-ntp 1
        ntpdate pool.ntp.org
        service ntpd start
    }
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    setenforce 0
    yum install -y \
        ntp \
        createrepo \
        psmisc \
        pdsh
    __time_cfg
}

sun::control_cm() {
    SERVER=cloudera-scm-server
    case $1 in
    0 | start)
        service $SERVER-db $1
        service $SERVER $1
        ;;
    1 | stop)
        service $SERVER $1
        service $SERVER-db $1
        ;;
    2 | restart)
        sun::control_cm 1
        sun::control_cm 0
        ;;
    esac
}

sun::install_cm() {
    MASTERIP=10.13.30.120
    CM=cloudera-manager
    #IP=$(hostname -I)
    #IP=${IP// /}
    IP=$MASTERIP
    PORT=8910
    (
        cat >/etc/yum.repos.d/local.repo <<EOF
[local]
name=local
baseurl=http://$IP:$PORT
enabled=1
gpgcheck=0
EOF
        yum install -y \
            $CM-server-db-2 \
            $CM-server \
            $CM-daemons
        #sun::control_cm start
    )
}

main() {
    set -x
    sun::on_begin
    case $1 in
    0 | copy) sun::nfs_copy ;;
    1 | cfg) sun::base_cfg ;;
    2 | install) sun::install_cm ;;
    3 | control) sun::control_cm $2 ;;
    esac
}
main $*
