#!/bin/bash

function try_source() {
  test -f $1 && . $1
}

export try_source
