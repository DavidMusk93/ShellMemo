#!/bin/bash

. ./common.sh

load_config()
{
  local i
  declare -A config
  config[version]=20.0
  config[versionCode]=20000

  config[appVersion]=7.3.5
  config[appVersionCode]=243

  config[prettyName]=true

  CONFIG_PROP=config.prop

  cp $CONFIG_PROP.sample $CONFIG_PROP
  for i in ${!config[@]}; do
    sed -i "/^$i/s/=.*$/=${config[$i]}/" $CONFIG_PROP
  done
}

extract_link
load_config

export ANDROID_HOME=~/Android/Sdk
export ANDROID_NDK_HOME=~/sun/ndk

BUILD_PY=./build.py

sed -i "s/'g++',/'g++', '-std=c++11', '-Wall', '-Wextra', '-pedantic',/" $BUILD_PY

$BUILD_PY -v all
