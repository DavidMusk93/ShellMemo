#!/bin/bash

function foo() {
    echo $1
}

foo "1 2 3"
foo 1 2 3
# bash $0 "1 2 3" 12 3
foo "$@"
