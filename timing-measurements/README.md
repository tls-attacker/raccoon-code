# Raccoon-Attacker-Side-Channel Analysis
This tool measures raccoon attack side-channels. For this purpose the tool repeatedly connects to a server and randomly send a CKE message which will either result in PMS with a leading zero byte or not. The tool records which case it sends and records the measured time. To get accurate time measurements the tool relies high-precision timing measurements executed with [Timing-Proxy](https://github.com/tls-attacker/Timing-Proxy). 
Building:
```
mvn clean install
```

To run the tool you best have a network card with high precision timestamping capabilities like the Nexus High Resolution Timestamp Capture NIC from Exablaze (CISCO), but any other high precision timestamping card will do.

First start the server you want to test, then start the timing-proxy, and then start this tool and connect to the timing proxy. The tool will then start to perform the measurments. This may take a while.

