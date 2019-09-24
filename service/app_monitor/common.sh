#!/bin/sh

PROJECT=sun_upload_service

WORK_DIR=$SUN_WORK_DIR
SHELL_DIR=$WORK_DIR/shell
LOG_DIR=$WORK_DIR/log

. $SHELL_DIR/functor.sh

DEBUG_TAG=/tmp/$PROJECT@debug
DEBUG_MODE=false
is_file $DEBUG_TAG && DEBUG_MODE=true

trap 'on_signal' SIGUSR1
