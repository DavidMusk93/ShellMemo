#!/bin/bash

. ./common.sh

set -x

extract_link

SDK_BUILD_TOOLS=$ANDROID_SDK_ROOT/build-tools
ALL_DX=($SDK_BUILD_TOOLS/*/dx)
SRC_DX=${ALL_DX[-1]}
DST_DX=~/bin/dx

ln -sfn $SRC_DX $DST_DX
command -v dx || exit 1

$GRADLE :edxp-core:zipSandhookRelease
unlink $DST_DX
