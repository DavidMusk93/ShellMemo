#!/bin/bash

#ref
# * http://webcave.org/installing-systemtap-on-centos-7/
# * https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/systemtap_beginners_guide/using-systemtap

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
}

main() {
    set -x
    sun::base_install
    sun::debuginfo_install
}
main "$@"
