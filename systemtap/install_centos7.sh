#!/bin/bash

#ref
# * http://webcave.org/installing-systemtap-on-centos-7/
# * https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/systemtap_beginners_guide/using-systemtap

setproxy() {
    local server port
    server=10.13.30.130
    port=2081
    export http_proxy=$server:$port
    export https_proxy=$http_proxy
}

sun::base_install() {
    yum install -y systemtap systemtap-runtime
}

sun::debuginfo_install() {
    KERNELRLS=$(uname -r)
    yum --enablerepo=*-debuginfo -y install \
        kernel-debuginfo-$KERNELRLS \
        kernel-devel-$KERNELRLS \
        kernel-debuginfo-common-$KERNELRLS
    #kernel-$KERNELRLS \
    #debug info
    #debuginfo-install bash-4.2.46-34.el7.x86_64

    #manual install
    # 1. goto http://debuginfo.centos.org/7/x86_64/
    # 2. download kernel-debuginfo*-`uname -r`
    # 3. rpn -ivh kernel-debuginfo-*
}

main() {
    set -x
    setproxy
    sun::base_install
    sun::debuginfo_install
}
main "$@"
