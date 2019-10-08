#!/bin/bash

. ./common.sh

golang::installed_prompt()
{
  log::info "golang is already installed"
  exit 0
}

golang::on_start()
{
  command -v go && golang::installed_prompt
  golang::dl_context
  if grep -q "$cfg_tag" $profile; then
    golang::installed_prompt
  else
    truncate_zero $tmp_profile
    append_text $tmp_profile   \
      "$cfg_tag"               \
      "export GOPATH=$HOME/go" \
      "export GOROOT=$go_home" \
      "export PATH=\$PATH:\$GOROOT/bin"

    truncate_zero $test_go
    append_text $test_go              \
      "package main"                  \
      $'\nimport "fmt"\n'             \
      "func main() {"                 \
      "  fmt.Printf(\"$test_str\n\")" \
      "}"
  fi
}

golang::dl_context()
{
  init_log_context
  rls_url='https://golang.org/dl/'
  dl_url='https://dl.google.com/go'
  pkg_ext='.tar.gz'
  pkg=
  test_str='Hello, world!'
  test_go='hello.go'
  go_home='/usr/local/go'
  profile=$HOME'/.bashrc'
  tmp_profile='/tmp/.go.cfg'
  cfg_tag='# golang'
}

golang::retrieve_pkg()
{
  local url url_p
  url_p=$dl_url'/go([0-9]+\.){3}linux-amd64'$pkg_ext
  url=`curl -s $rls_url | grep -oE $url_p | head -n 1`
  if non_empty $url; then
    pkg=`basename $url`
    fetch_pkg $url
    return $?
  fi
  return 1
}

golang::install()
{
  [ -d $go_home ] || sudo tar zxvf $pkg -C '/usr/local'
  . $tmp_profile
  if go run $test_go; then
    log::success "golang is successfully installed"
    cat $tmp_profile >> $profile
  fi
}

golang::main()
{
  golang::on_start
  if golang::retrieve_pkg; then
    golang::install
  else
    log::error "fail to retrieve golang package"
  fi
}

set -x
golang::main
