#!/bin/bash

# Script for auto updating the ThinsIX forwarder to that latest release.
#
# These scripts have been inspired by the scripts of Wheaties466:
# https://github.com/Wheaties466/helium_miner_scripts/blob/master/miner_latest.sh
# Where Wheaties466 has not applied a license, this script is published
# under a Creative Commons Attribution-NonCommercial 4.0 International License.
#
# DISCLAIMER
# ----------
# This repository is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# LICENSE
# -------
# This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License:
# http://creativecommons.org/licenses/by-nc/4.0/
#
# The ThingsIX scripts of PE1MEW are free software:
# You can redistribute it and/or modify it under the terms of a
# Creative Commons Attribution-NonCommercial 4.0 International License
# (http://creativecommons.org/licenses/by-nc/4.0/) by
# PE1MEW (http://pe1mew.nl) E-mail: pe1mew@pe1mew.nl
#

# Set default values
FORWARDER=thingsix-forwarder
GWPORT=1690
NET=test
MY_CONFIG_FILE=my-test-config.yaml
RELEASE_URL='https://api.github.com/repos/ThingsIXFoundation/packet-handling/releases'
DOCKER_PULL_URL='ghcr.io/thingsixfoundation/packet-handling/forwarder:'

# Test is jq is installed.
testJQ=$(which jq)

if [ $? -ne 0 ]; then
       	sudo apt install jq curl -y 
fi

# Read switches to override any default values for non-standard configs
while getopts f:p:c:n: flag
do
   case "${flag}" in
      f) FORWARDER=${OPTARG};;
      p) GWPORT=${OPTARG};;
      c) MY_CONFIG_FILE=${OPTARG};;
      n) NET=${OPTARG};;
   esac
done

# print date

date

# Autodetect running image version and set arch
version_running_image=$(docker container inspect -f '{{.Config.Image}}' $FORWARDER | awk -F: '{print $2}')

# Detect latest release at Github
release=$(curl -s $RELEASE_URL | jq -r '.[0].tag_name')
version_git=${release:1}

echo "Running forwarder version:" $version_running_image;
echo "Released forwarder version:" $version_git;

if [ "$version_running_image" = "$version_git" ];
then    echo "already on the latest version."
        exit 0
fi

echo "Stopping and removing old forwarder..."

docker stop $FORWARDER && docker rm $FORWARDER

echo "Deleting old forwarder images..."

for a in `docker images ghcr.io/thingsixfoundation/packet-handling/forwarder | grep "ghcr.io/thingsixfoundation/packet-handling/forwarder" | awk '{print $3}'`; do
	image_cleanup=$(docker images | grep $a | awk '{print $2}')
	#change this to $running_image if you want to keep the last 2 images
	if [ $image_cleanup = $miner_latest ]; then
		continue
        else
		echo "Cleaning up: " $image_cleanup
	       	docker image rm $a
        fi
done

echo "Provisioning new forwarder version..."

# docker run -d --restart always --name thingsix-forwarder  -p 1690:1690/udp  -v /etc/thingsix-forwarder:/etc/thingsix-forwarder  ghcr.io/thingsixfoundation/packet-handling/forwarder:0.0.1-beta.2 --config /etc/thingsix-forwarder/my-custom-config.yaml

docker run -d --restart always --name $FORWARDER --publish $GWPORT:$GWPORT/udp -v /etc/thingsix-forwarder:/etc/thingsix-forwarder $DOCKER_PULL_URL$version_git --config /etc/thingsix-forwarder/$MY_CONFIG_FILE --net $NET
