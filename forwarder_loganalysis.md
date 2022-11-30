# Log analysis of ThingsIX forwarder. 
When the forwarder is running in a Docker container we need Docker to see activity on the forwarder.

## Show live log
To start watching the actual activity use the following command: 
```
docker logs thingsix-forwarder -n 0 -f

```
This command will 'follow' the log and will present 0 previous entries in the log. 

## Filter a log
To filter the log ***grep*** is being used:
```
docker logs thingsix-forwarder -n 0 -f 2>&1 | grep "snr"
```
This command will only show log entries that contain the text __snr___.

```
docker logs thingsix-forwarder -n 0 -f 2>&1 | grep -v "snr"
```
This command will show all log entries except the ones that contain __snr__.

