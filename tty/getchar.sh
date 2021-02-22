#!/bin/bash

sun::getchar() {
    termios=$(stty -g)
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2>/dev/null
    stty $termios
}
set -x
answer=$(sun::getchar)
