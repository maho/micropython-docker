#!/bin/bash

TRAVIS=.travis.yml
SCRIPT=/tmp/$$.script.sh


yq -r '.env.global[]' < $TRAVIS > $SCRIPT

yq -r '.jobs.include | .[] | select(.name == "esp32 ESP-IDFv3 port build").install[]' < $TRAVIS >> $SCRIPT
yq -r '.jobs.include | .[] | select(.name == "esp32 ESP-IDFv3 port build").script[]' < $TRAVIS >> $SCRIPT

sed -i 's/apt-get install/apt-get install -y/' $SCRIPT

set -xe
. $SCRIPT

