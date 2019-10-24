#!/bin/bash

. ./common.sh

extract_link

BUILD_GRADLE=riru-core/build.gradle
export PATH=$PATH:~/sun/ndk

sed -i "s/commandLine 'sh',/commandLine/" $BUILD_GRADLE

$GRADLE :riru-core:assembleMagiskRelease
