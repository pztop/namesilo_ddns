#!/bin/bash

##=================================
##added by alphazealot 20200411
## Add some colors for debug purpose.
function blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
function green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
function red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
function yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
function bred(){
    echo -e "\033[31m\033[01m\033[05m$1\033[0m"
}
function byellow(){
    echo -e "\033[33m\033[01m\033[05m$1\033[0m"
}
##=================================



##Domain name:
DOMAIN="mydomain.tld"

##Host name. 
##If you want manage host "myhost.mydomain.tld", then

#HOST="myhost"

##=================================
##added by alphazealot 20200411
##If host name is empty, there should no 'dot' before the domain.
if [$HOST == ""]; then
	HOST=""
else
	HOST=$HOST.
fi
##=================================


##APIKEY obtained from Namesilo:
APIKEY="your_api_key"

## Do not edit lines below ##
## Unless you don't want to see the debug shit

##Saved history pubic IP from last check
IP_FILE="./MyPubIP"

##Response from Namesilo
RESPONSE="/tmp/namesilo_response.xml"

##Get the current public IP 
green "Getting the current ip from http://icanhazip.com"
CUR_IP=$(curl -s http://icanhazip.com)
green "The current ip is: $CUR_IP"


##Exit if curl failed
if [ $? -ne 0 ]; then
	exit 1
fi

##Check file for previous IP address
##=================================
##commented by alphazealot, 20200411
##It can be useless if the REGISTERED_IP method worked.
#if [ -f $IP_FILE ]; then
#	KNOWN_IP=$(cat $IP_FILE)
#else
#	KNOWN_IP=
#fi
##=================================
##added by alphazealot 20200411
# The original script only check the last run result to the current ip,
# However, if people do some changes manually on namesilo, the script might fail.
# So change the criteria to compare the current ip with the ip stores in DNS server (give it a name: registered_ip）,
# which can be get via curl method.
curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > $DOMAIN.xml
RECORD_ID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '$HOST$DOMAIN' ]" $DOMAIN.xml | grep -oP '(?<=<record_id>).*?(?=</record_id>)'`
REGISTERED_IP=`xmllint --xpath "//namesilo/reply/resource_record/value[../host/text() = '$HOST$DOMAIN' ]" $DOMAIN.xml | grep -oP '(?<=<value>).*?(?=</value>)'`
yellow "The registered ip is: $REGISTERED_IP"
##=================================


##See if the IP has changed
if [ "$CUR_IP" != "$REGISTERED_IP" ]; then
	echo $CUR_IP > $IP_FILE
	logger -t IP.Check -- Public IP changed to $CUR_IP

	##Update DNS record in Namesilo:
	##===============================
	##commented by alphazealot, 20200411
#	curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > $DOMAIN.xml 
#	RECORD_ID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '$HOST.$DOMAIN' ]" $DOMAIN.xml | grep -oP '(?<=<record_id>).*?(?=</record_id>)'`
	##===============================
	green "Start registering the new ip to the DNS..."
	curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$RECORD_ID&rrhost=$HOST&rrvalue=$CUR_IP&rrttl=7207" > $RESPONSE
	RESPONSE_CODE=`xmllint --xpath "//namesilo/reply/code/text()" $RESPONSE`
	case $RESPONSE_CODE in
		300)
			green "Update successful, now $HOST$DOMAIN IP address is $CUR_IP"	##added by alphazealot, 20200411
			logger -t IP.Check -- Update success. Now $HOST$DOMAIN IP address is $CUR_IP;;
		280)
			yellow "Duplicated records. No need to update."				##added by alphazealot, 20200411
			logger -t IP.Check -- Duplicate record exist. No update necessary;;
		*)
			red "Something wrong...Please check."					##added by alphazealot, 20200411
			logger -t IP.Check -- DDNS update failed!;;
	esac

else
	yellow "No need to update."								##added by alphazealot, 20200411
	logger -t IP.Check -- NO IP change
fi

exit 0
