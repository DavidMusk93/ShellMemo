#!/bin/bash

set -x

#@ref
#  *https://www.jianshu.com/p/925a135490c3

#URL='connect.rom.miui.com/generate_204'
URL='captive.v2ex.co/generate_204'

adb shell < <(
echo settings put global captive_portal_http_url http://$URL
echo settings put global captive_portal_https_url https://$URL
)
