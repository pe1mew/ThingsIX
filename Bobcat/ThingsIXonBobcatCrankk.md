# Installing ThingsIX on a [Bobcat Miner 300](https://crankk.io/guides/) with Crankk image
For this howto, it is assumed that the Crankk Image for Bobcat [Bobcat Miner 300 (G290/G295- RK3566 - 2GB)](https://crankk.io/guides/) successfully is installed and running.

The Crankk image for the Bobcat is installed on eMMC and mounted on the file system in RO and RW parts. Therefore we need to install ThingsIX forwarder in such a place that it is persistent over a reboot of the OS. The location used is `/usr`.

This installation uses a script for both installing and updating the ThingsIX forwarder on the Bobcat.

**For this howto intermediate knowledge of Linux is helpful.** 


## Preparations
 0. SSH into the Bobcat with user `crankk` and password `B@tch0n3`
 1. Make a directory `/usr/thingsix-forwarder`
 2. Create a file config.yaml and fill it with the following content:
### config.yaml
```
# Copyright 2022 Stichting ThingsIX Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

forwarder:
    # Described backend for the gateways
    backend:
        # Use Semtech UDP forwarder backend
        semtech_udp:
            # ip:port to bind the UDP listener to, ensure it is accessible by the gateways
            #
            # Example: 0.0.0.0:1680 to listen on port 1680 for all network interfaces.
            udp_bind: 0.0.0.0:1690
            # Fake RX timestamp.
            #
            # Fake the RX time when the gateways do not have GPS, in which case
            # the time would otherwise be unset.
            fake_rx_time: false

    # Gateways that can use this forwarder
    gateways:
        # Smart contract that verifies onboarding message and if valid registers
        # the gateway in the ThingsIX gateway registry.
        # batch_onboarder:
        #     # Batch onboarder smart contract address.
        #     address: "0x0000000000000000000000000000000000000000"

        # ThingsIX gateway registry.
        #
        # The registry contains all onboarded gateways with optional details set
        # by their owner. The forwarder periodically synces with the registry to
        # retrieve owner and extra gateway details.
        registry:
            # Retrieve gateway data from the registry through the API ThingsIX.
            # thingsix_api:
            # API endpoint
            endpoint: https://api.thingsix.com/gateways/v1/{id}

            # Retrieve gateway data direct from the ThingsIX gateway registry
            # smart contract. This requires blockchain.polygon configuration.
            # on_chain:
            #     # ThingsIX gateway registry address.
            #     address: "0x0000000000000000000000000000000000000000"

        # Forwarder gateway store
        store:

            # File based gateway store. This store contains all gateways and
            # their identity keys.
            #
            # Full gateway store path on the file system
            file: /etc/thingsix-forwarder/gateways.yaml

            # Postgresql bases gateway store. This store contains all gateways
            # and their identity keys. Gateway records are store in the
            # gateway_store table.
            #
            # Connection details are set on the root configuration level.
            # postgresql: false

            # Interval on which the forwarder reloads the gateways from the
            # configured backend, file or postgresql.
            #
            # Set to 0m when the gateway store must not be hot reloaded. This is
            # adviced when store is not expected to change.
            #
            # Default value is 1 minute.
            refresh: 1h

            # Set a default frequency plan for gateways that are not onboarded.
            #
            # By default the forwarder will only forward data for gateways in its
            # store that are onboarded and have their location and frequency plan
            # set. With this option the forwarder will use the default frequency
            # plan for gateways in its store that are not fully onboarded and
            # forwards their data.
            #
            # Valid values are: EU868, US915, CN779, EU433, AU915, CN470, AS923,
            #                   AS923-2, AS923-3, KR920, IN865, RU864, AS923-4
            default_frequency_plan: EU868

        # Optionally record gateway local id's for unknown gateways to a file.
        # This file can be imported into the gateway store later. This is
        # convenient if you have a lot of gateways that you would need to
        # add to the store 1 by 1.
        record_unknown:
            # Path to file where unknown gateways are recorded, must be
            # writeable by the forwarder. If file and postgresql are not set the
            # default is to use file /etc/thingsix-forwarder/unknown_gateways.yaml.
            #
            # Set to an empty string to disable recording.
            file: /etc/thingsix-forwarder/unknown_gateways.yaml

            # Store local id's for unknown gateways in PostgreSQL. Database
            # postgresql details are set on the root configuration level.
            # Unknown gateways are recorded in the unknown_gateways table.
            #
            # Set to true to enable recording in postgresql, remove or set to
            # false to disable.
            # postgresql: false

    # Routers to forward gateway data to.
    routers:
        # List with default routers
        #
        # Default routers are routers that will receive all gateway data and
        # don't have to be registered at ThingsIX.

        #default:
        #    - endpoint: localhost:3200
        #      name: v47

        # Fetch routers from the ThingsIX router registry smart contract.
        #
        # This address is environment specific, see the ThingsIX
        # documentation for a list of router registry addresses per
        # environment. This requires blockchain.polygon configuration.

        #on_chain:
            #registry: 0xd6bcc904C2B312f9a3893d9D2f5f2b6b0e86f9a1

            # retrieve router list from registry every interval

            #interval: 30m

        # Retrieve routers from the ThingsIX API.
        thingsix_api:
            # ThingsIX router API.
            #
            # ThingsIX offers an API to fetch registered routers from. This API
            # syncs periodically with the router registry smart contract. The
            # preferred method is to fetch them direct from the smart contract
            # using the on_chain method. If that is not possible the API can be
            # used.
            endpoint: https://api.thingsix.com/routers/v1/snapshot

            # Interval when to fetch the latest set of routers from the ThingsIX
            # API.
            #
            # Routes don't frequently change and are cached. There is no point
            # in setting this interval to a very small value.
            interval: 30m

# Logging related configuration
log:
    # log level
    level: info      # [trace,debug,info,warn,error,fatal,panic]
    # Include timestamp in logging
    timestamp: true  # [true, false]

# Blockchain related configuration
blockchain:
    # Blockchain
    polygon:
        # Polygon node RPC endpoint
        endpoint: https://polygon-rpc.com
        # Polygon chain id; mainnet=137, mumbai testnet=80001
        chain_id: 137
        # Block confirmations, polygon blocks are final after 128 confirmations
        confirmations: 128

# Database releated configuration
database:
    # Configure a Postgresql database
    postgresql:
        # uri: <uri>
        # Postgresql database name
        database: thingsix-gateways
        # Driver name
        drivername: postgres
        # Database host
        host: localhost
        # Database username
        user: thingsix-forwarder
        # Database password
        password: mypasswd
        # Database port
        port: 5432
        # Enable sslmode
        sslmode: disable
        # Enable query logging
        enableLogging: false
```
 3. Create a file named `thingsixupdater.sh` and fill it with the following script:
# Installation and update script
```
# Script for auto-updating the ThinsIX forwarder to the latest release.
#
# This script was inspired by the scripts of Wheaties466:
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
NET=main
MY_CONFIG_FILE=config.yaml
RELEASE_URL='https://api.github.com/repos/ThingsIXFoundation/packet-handling/releases'
DOCKER_PULL_URL='ghcr.io/thingsixfoundation/packet-handling/forwarder:'

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
        # Change this to $running_image if you want to keep the last 2 images
        if [ $image_cleanup = $miner_latest ]; then
                continue
        else
                echo "Cleaning up: " $image_cleanup
                docker image rm $a
        fi
done

echo "Provisioning new forwarder version..."


docker run -d --restart always --name $FORWARDER --publish $GWPORT:$GWPORT/udp -v /data/usr/thingsix-forwarder:/etc/thingsix-forwarder $DOCKER_PULL_URL$version_git --config /etc/thingsix-forwarder/$MY_CONFIG_FILE --net $NET

```
 5. Make the script executable with the command `chmod +x thingsixupdater.sh`
 6. Execute the script to install the ThingsIX forwarder container and run it. `./thingsixupdater.sh`
 7. Check if the docker container for ThingsIX forwarder is running with the command: `docker ps`.
 When all is OK, the following line can be found: 
```
CONTAINER ID   IMAGE                                                        COMMAND                  CREATED          STATUS          PORTS                    NAMES
ad4feba89b0b   ghcr.io/thingsixfoundation/packet-handling/forwarder:1.2.1   "./forwarder --confi…"   26 minutes ago   Up 24 minutes   0.0.0.0:1690->1690/udp   thingsix-forwarder
```
 8. Configure the Crankk gateway to forward to the ThingsIX forwarder by adding `,127.0.0.1:1690` to the _"forwards To:"_ rule. The complete rule will be: `127.0.0.1:1700,127.0.0.1:1680,127.0.0.1:1690`.
 9. Click _save_ and the gateway will restart which will result in your SSH connection to terminate. 
 10. After restart login with ssh.
 11. When the gateway is restarted, ensure that the gateway is forwarding to the ThingsIX forwarder. In the file `/usr/thingsix-forwarder/unknown_gateways.yaml` you see something like this: 
```
- local_id: 7eea21fffee636f0
  first_seen: 1693250188
```
 When this is okay, you are ready to onboard your gateway. 

# Onboard gateway
To onboard the gateway to ThingsIX you need a Wallet on Polygon. Use the public address of this wallet in the following commands. This command will import all gateways in file `/usr/thingsix-forwarder/unknown_gateways.yaml` and push them to ThingsIX. 

 1. Execute the following command with the correct wallet address:
```
docker exec thingsix-forwarder ./forwarder gateway import-and-push <walletAddressPublicKey> --json
```
 2. It is good practice to save the JSON that is returned from the command:
### Json returned on onboard
```
[{"address":"0xcf107800833233368ae938531ac3d246bf802651","chainId":137,"gatewayId":"0x7923162fc625809c2667a555b92e78a2493563c727e2cb7341c22dcc50b3d038","localId":"7eea21fffee636f0","networkId":"303e5a2b071f63e4","owner":"<walletAddressPublicKey>","signature":"0x276c784dd90fac237f355454ae55dabe117df9a7679c52d636ced271527c5e955c9c475e7eef737069d763bb25a729fd06a452b356ae7e3c136186e58abdc96f1c","version":0}]
```
 3. The result of the onboarding command will produce teh local gatewayEUI and the private key for this gateway in file `/usr/thingsix-forwarder/gateways.yaml`. **Secure the content of this file for recovery purposes!**
### gateways.yaml
```
- local_id: 7eea21fffee636f0
  private_key: 2aa91deadbeef5c95550d442f7701856618adeadbeefd26831eadeadbeef64bb
```
 3. Ensure to have THIX in your wallet to pay for onboarding in ThingsIX and updating gateway details.
 4. Onboard your gateway using [the instructions at ThingsIX documentation](https://docs.thingsix.com/for-gateway-owners/onboarding-gateway). 

# Automate updating ThingsIX Forwarder
**Please note that although unattended updates are convenient, sometimes updates are unwanted. There is a risk involved with unattended updates.**

To automate updating the ThingsIX forwarder Crontab can be used. Crontab will execute the update script daily at 01:00. 

 1. To install the update edit crontab with the command `crontab -e`. An editor will start (Nano) and add the following lines at the end of the file: 
```
# Check for updates on ThingsIX forwarder daily at 1
0 1 * * * cd /usr/thingsix-forwarder && ./thingsixupdater.sh >> thingsixupdater.log
```
 2. Quit editing crontab by invoking key `ctrl-x` followed by `y`(yes) followed by `enter` to write the changes to disk. 

The result of the update is written into a log file for analysis. 
### thingsixupdater.log
```
Wed Aug 30 09:27:10 UTC 2023
Running forwarder version: 1.2.1
Released forwarder version: 1.2.1
already on the latest version.
```

