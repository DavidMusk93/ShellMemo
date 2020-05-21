#!/bin/bash

adb::conn()
{
  adb connect $1
}

adb::disconn()
{
  adb disconnect $1
}
