#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

scp -rp techdufus@10.0.0.5:/etc/pihole/dns-servers.conf $SCRIPT_DIR/../files/config/
scp -rp techdufus@10.0.0.5:/etc/pihole/custom.list $SCRIPT_DIR/../files/config/
scp -rp techdufus@10.0.0.5:/etc/pihole/04-pihole-static-dhcp.conf.gsb $SCRIPT_DIR/../files/config/
scp -rp techdufus@10.0.0.5:/etc/pihole/05-pihole-custom-cname.conf $SCRIPT_DIR/../files/config/

ssh techdufus@10.0.0.5 'sudo sqlite3 /etc/pihole/gravity.db -header -csv "SELECT * FROM adlist" > /tmp/adlist.csv'
scp -rp techdufus@10.0.0.5:/tmp/adlist.csv $SCRIPT_DIR/../files/config/
