#!/bin/bash

set -x

function starts_with() {
  case "$1" in
    "$2"*) return 0;;
    *)     return 1;;
  esac
}

function ends_with() {
  case "$1" in
    *"$2") return 0;;
    *)     return 1;;
  esac
}

function check_cmd() {
  return $?
}

function check_git() {
  test -d $1 && (cd $1 && git status &>/dev/null)
}

#-----------------------------------------------------

function retrieve_href() {
  local html=`echo $1 | md5sum`
  html=/tmp/${html%% *}.html
  test -f $html || curl --silent $1 > $html
  sed -E -n 's/.*href="([^"]+\/'$2')".*/\1/gp' $html
}

function download_app() {
  local url=`retrieve_href $2 $3 | head -n 1`
  starts_with $url $1 || url=$1$url
  curl -L $url -o $4/$3
}

function on_init() {
  DOWNLOAD_LINK_PREFIX=https://github.com
  RELEASES_LINK=https://github.com/Trojan-Qt5/Trojan-Qt5/releases
  APP_NAME=Trojan-Qt5-Linux.AppImage
  APP_DIR=~/apps
  WORK_DIR=`pwd`
  TROJAN_DESKTOP=trojan-qt.desktop
  mkdir -p $APP_DIR
}
on_init

cat > $TROJAN_DESKTOP << EOF
[Desktop Entry]
Icon=$APP_DIR/Trojan-Qt5/resources/icons/trojan-qt5.icns
Exec=$APP_DIR/Trojan-Qt5-Linux.AppImage
Version=1.0
Type=Application
Name=trojan-qt
Terminal=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
X-GNOME-Autostart-Delay=10
X-MATE-Autostart-Delay=10
X-KDE-autostart-after=panel
EOF

function on_success() {
  local AUTOSTART_DIR=~/.config/autostart
  test -d $AUTOSTART_DIR || mkdir $AUTOSTART_DIR -m 700
  (cd $AUTOSTART_DIR              && ln -sfn $WORK_DIR/$TROJAN_DESKTOP)
  (cd ~/.local/share/applications && ln -sfn $WORK_DIR/$TROJAN_DESKTOP)
  chmod +x $APP_DIR/$APP_NAME
}

function main() {
  local repo=`dirname $RELEASES_LINK`
  local project=`basename $repo`
  check_git $APP_DIR/$project || git clone $repo.git $APP_DIR/$project
  check_cmd && download_app \
    $DOWNLOAD_LINK_PREFIX \
    $RELEASES_LINK \
    $APP_NAME \
    $APP_DIR && on_success
}
main
