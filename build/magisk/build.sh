#!/bin/bash

. ./common.sh

on_start()
{
  trap 'check_rc && on_success || on_failure' EXIT

  load_variable
  check_directory
  check_file

  exec {FD_NULL}>/dev/null
  exec {FD_LOCK}>$LOCK_FILE

  lock $FD_LOCK || abort 'There is an instance in progress.'
}

on_success()
{
  do_clean
  return 0
}

on_failure()
{
  do_clean
}

do_clean()
{
  local i
  close_fd $FD_NULL
  unlock
  close_fd $FD_LOCK

  for i in ${PROJECTS[@]}; do
    (cd ${LINK_ALIAS[$i]}; git stash clear;)
  done
}

check_directory()
{
  mkdir -p $LOG_DIR
  mkdir -p $BRANCH
}

check_file()
{
  touch $LOCK_FILE
  rm -f $BUILD_DONE
}

load_variable()
{
  local i j=0
  FD_NULL=
  FD_LOCK=
  TMP_DIR=/tmp/magisk
  LOG_DIR=$TMP_DIR/log
  LOCK_FILE=$TMP_DIR/magisk@build
  BUILD_DONE=$TMP_DIR/magisk@done

  readonly GIT_HOST=192.168.10.101
  readonly GIT_PORT=29418
  readonly GIT_PATH=ssh://$GIT_HOST:$GIT_PORT

  PROJECTS=(Magisk Riru EdXposed EdXposedManager)
  declare -g -A LINK_ALIAS
  for i in ${PROJECTS[@]}; do LINK_ALIAS[$i]="x$((j++))"; done

  BRANCH=master
}

sync_project()
{
  local project
  project=$BRANCH/$1

  if [ -d $project ]; then
    # Keep git-pull's output, as we should know whether this is a
    # valid repository. For example, if we synchronise this git
    # from another git in different machine, this git config may
    # changed, pull action would be failed immediately.
    (cd $project; git stash &>$FD_NULL; git pull --rebase;)
  else
    git clone --single-branch --branch $BRANCH $GIT_PATH/$1 $project
  fi
  ln -sfn $project ${LINK_ALIAS[$1]}
}

build()
{
  local i log pid
  declare -A pid_map

  for i in build_*.sh; do
    log=$LOG_DIR/$i@magisk.log
    bash $i &>$log &
    pid_map[$!]=$log
  done

  while :; do
    i=0
    for pid in ${!pid_map[@]}; do
      if ! kill -0 $pid 2>&$FD_NULL; then
        wait $pid
        # If a task return non-zero, print the last 10-line of its log.
        check_rc || tail -n 10 ${pid_map[$pid]}
        unset pid_map[$pid]
        continue
      fi
      ((++i))
    done
    sleep 2
    [ $i -eq 0 ] && break
  done
  touch $BUILD_DONE
}

build_prompt()
{
  local i pre dot PROMPT MAX
  PROMPT='wait'
  pre=
  for ((i=0;i<6;++i)); do
    dot[$i]="$pre."
    pre=${dot[$i]}
  done
  MAX=`expr ${#PROMPT} + ${#dot[-1]}`

  echo ""
  for ((i=0;i<6;++i)); do
    [ -f $BUILD_DONE ] && break
    printf "\r$PROMPT${dot[$i]}"
    sleep 2
    if [ $i -eq 5 ]; then
      i=-1
      printf "\r%*s" $MAX
    fi
  done
  echo $'\rBUILD DONE!\n'
}

main()
{
  local i
  on_start

  for i in ${PROJECTS[@]}; do
    sync_project $i &
  done
  wait

  build_prompt &
  build
  wait
}

#set -x
main
