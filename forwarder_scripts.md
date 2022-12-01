# Forwarder scripts
These scripts help in managing the ThingsIX installation at your server. 

 - [install_latest_forwarder.sh](./install_latest_forwarder.sh) Install latest version of forwarder.
 - [remove_all_forwarder.sh](./remove_all_forwarder.sh) Remove install forwarder(s) and cleanup containers.
 - [update_forwarder.sh](./update_forwarder.sh) Update forwarder to the latest version if possible.
 
## Note
These scripts depend on __jq__ being installed and will install __jq__ and __curl__ when not installed. 

# Script manuals

## install_latest_forwarder.sh
This script will install the latest version of ThingsIX forwarder. 

### Note
 - When there is an existing installation of forwarder, the script will terminate. Before continuing use the removal script.
 - forwarder will connect to test network
 - gateway port 1690 will be configured
 - config file __my-test-config.yaml__ will be used. 


## remove_all_forwarder.sh
This script will remove all installed forwarders and cleanup docker containers.


## update_forwarder.sh

### Note: 
 - forwarder will connect to test network
 - gateway port 1690 will be configured
 - config file __my-test-config.yaml__ will be used


### contab
Automatic updates can be obtained using the update script using __crontab__.

Add these lines to crontab to have the system check daily for updates:
```
# Check for updates on ThingsIX forwarder image daily at 1 AM
0 1 * * * cd ~/ThingsIX && ./update_forwarder.sh >> update_forwarder.log 2>&1
```
