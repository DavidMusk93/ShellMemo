#!/bin/bash

replace()
{
  sed -i "s/$2/$3/g" $1
}

regexReplace()
{
  sed -i -E "s/$2/$3/g" $1
}

correctGradleVersion()
{
  readonly local BuildGradle=build.gradle
  readonly local GoogleRepo='google()'
  # replace $BuildGradle '1.5.0' '3.1.2'
  regexReplace $BuildGradle 'gradle:[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}' 'gradle:3.1.2'
  if ! grep -q $GoogleRepo $BuildGradle; then
    replace $BuildGradle 'jcenter()' "jcenter()\n$GoogleRepo"
  fi
  # replace gradle/wrapper/gradle-wrapper.properties '5.4.1' '4.4'
  regexReplace gradle/wrapper/gradle-wrapper.properties 'gradle-[0-9]+(\.[0-9]{1,2})+-all' 'gradle-4.4-all'
}

(cd $1 && correctGradleVersion)
