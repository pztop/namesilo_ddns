#!/bin/bash

##Domain name:
DOMAIN="mydomain.tld"

##Host name. 
##If you want manage host "myhost.mydomain.tld", then
HOST="myhost"

##APIKEY obtained from Namesilo:
APIKEY="c40031261ee449037a4b4"

##Saved history pubic IP from last check
IP_FILE="/var/log/MyPubIP"

##Get the current public IP 
CUR_IP=$(curl -s http://icanhazip.com)

##Exit if curl failed
if [ $? -ne 0 ]; then
   exit 1
fi

##Check file for previous IP address
if [ -f $IP_FILE ]; then
  KNOWN_IP=$(cat $IP_FILE)
else
  KNOWN_IP=
fi

##See if the IP has changed
if [ "$CUR_IP" != "$KNOWN_IP" ]; then
  echo $CUR_IP > $IP_FILE
  logger -t IP.Check -- Public IP changed to $CUR_IP

  ##Update DNS record in Namesilo:
  curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > $DOMAIN.xml 
  RECORD_ID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '$HOST.$DOMAIN' ]" $DOMAIN.xml | grep -oP '(?<=<record_id>).*?(?=</record_id>)'`
  curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$RECORD_ID&rrhost=$HOST&rrvalue=$CUR_IP&rrttl=7207"
else
  logger -t IP.Check -- NO IP change
fi

exit 0
