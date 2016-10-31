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
IP_FILE="/var/tmp/MyPubIP"

##Time IP last updated or 'No IP change' log message output
IP_TIME="/var/tmp/MyIPTime"

##How often to output 'No IP change' log messages
NO_IP_CHANGE_TIME=86400

##Response from Namesilo
RESPONSE="/tmp/namesilo_response.xml"

##Choose randomly which OpenDNS resolver to use
RESOLVER=resolver$(echo $((($RANDOM%4)+1))).opendns.com
##Get the current public IP using DNS
CUR_IP="$(dig +short myip.opendns.com @$RESOLVER)"
ODRC=$?

## Try google dns if opendns failed
if [ $ODRC -ne 0 ]; then
   logger -t IP.Check -- IP Lookup at $RESOLVER failed!
   sleep 5
##Choose randomly which Google resolver to use
   RESOLVER=ns$(echo $((($RANDOM%4)+1))).google.com
##Get the current public IP 
   IPQUOTED=$(dig TXT +short o-o.myaddr.l.google.com @$RESOLVER)
   GORC=$?
## Exit if google failed
   if [ $GORC -ne 0 ]; then
     logger -t IP.Check -- IP Lookup at $RESOLVER failed!
     exit 1
   fi
   CUR_IP=$(echo $IPQUOTED | awk -F'"' '{ print $2}')
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
  logger -t IP.Check -- Public IP changed to $CUR_IP from $RESOLVER

  ##Update DNS record in Namesilo:
  curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > $DOMAIN.xml 
  RECORD_ID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '$HOST.$DOMAIN' ]" $DOMAIN.xml | grep -oP '(?<=<record_id>).*?(?=</record_id>)'`
  curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$RECORD_ID&rrhost=$HOST&rrvalue=$CUR_IP&rrttl=3600" > $RESPONSE
    RESPONSE_CODE=`xmllint --xpath "//namesilo/reply/code/text()"  $RESPONSE`
       case $RESPONSE_CODE in
       300)
         date "+%s" > $IP_TIME
         logger -t IP.Check -- Update success. Now $HOST.$DOMAIN IP address is $CUR_IP;;
       280)
         logger -t IP.Check -- Duplicate record exists. No update necessary;;
       *)
         ## put the old IP back, so that the update will be tried next time
         echo $KNOWN_IP > $IP_FILE
         logger -t IP.Check -- DDNS update failed code $RESPONSE_CODE!;;
     esac

else
  ## Only log all these events NO_IP_CHANGE_TIME after last update
  [ $(date "+%s") -gt $((($(cat $IP_TIME)+$NO_IP_CHANGE_TIME))) ] &&
    logger -t IP.Check -- NO IP change from $RESOLVER &&
    date "+%s" > $IP_TIME
fi

exit 0
