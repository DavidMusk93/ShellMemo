#!/bin/bash

sun::rc::auxiliry_setting() {
    alias ll='ls -al'
}

sun::rc::login_hook() {
    [ $USER = trafodion ] && cd ~/esgyndb
}

sun::rc::main() {
    sun::rc::auxiliry_setting
    sun::rc::login_hook
}
sun::rc::main
