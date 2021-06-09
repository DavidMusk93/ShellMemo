#!/bin/bash

while :; do
    echo "@@@@@@ $(date)"
    jps | grep WorkloadDriver
    lsof -i -P -n | grep 10.10.12.25:23
    echo "@@@@@@"
    echo
    sleep 10
done
