#!/bin/bash

sun::remote::initialize() {
    PDSH='pdsh -R exec'
    PDCP='pdcp -R ssh'
    SSHCMD='ssh %h'
}
sun::remote::initialize
