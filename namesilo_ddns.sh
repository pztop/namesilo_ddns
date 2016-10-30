#!/bin/bash

##Domain name:
DOMAIN="mydomain.tld"

##Host name. 
##If you want manage host "myhost.mydomain.tld", then
HOST="myhost"

##APIKEY obtained from Namesilo:
APIKEY="c40031261ee449037a4b4"

## Do not edit lines below ##

##Saved history pubic IP from last check
IP_FILE="/var/log/MyPubIP"

##Response from Namesilo
RESPONSE="/tmp/namesilo_response.xml"

##Get the current public IP sing DNS
CUR_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"

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
  curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$RECORD_ID&rrhost=$HOST&rrvalue=$CUR_IP&rrttl=7207" > $RESPONSE
    RESPONSE_CODE=`xmllint --xpath "//namesilo/reply/code/text()"  $RESPONSE`
       case $RESPONSE_CODE in
       300)
         logger -t IP.Check -- Update success. Now $HOST.$DOMAIN IP address is $CUR_IP;;
       280)
         logger -t IP.Check -- Duplicate record exist. No update necessary;;
       *)
         logger -t IP.Check -- DDNS update failed!;;
     esac

else
  logger -t IP.Check -- NO IP change
fi

exit 0
