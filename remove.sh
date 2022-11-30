#!/bin/bash

# Script for removing all docker contactiners with ThingsIX forwarders.
#
# These scripts have been inspired by the scriots of Wheaties466:
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

# Autodetect running image version and set arch
version_running_image=$(docker container inspect -f '{{.Config.Image}}' $FORWARDER | awk -F: '{print $2}')

echo "Running forwarder version:" $version_running_image;

echo "Stopping and removing old forwarder..."

docker stop $FORWARDER && docker rm $FORWARDER

echo "Deleting old forwarder images..."

for a in `docker images ghcr.io/thingsixfoundation/packet-handling/forwarder | grep "ghcr.io/thingsixfoundation/packet-handling/forwarder" | awk '{print $3}'`; do
	image_cleanup=$(docker images | grep $a | awk '{print $2}')
	echo "Cleaning up: " $image_cleanup
       	docker image rm $a
done
