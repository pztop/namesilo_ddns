## alphazelaot 2200411

The original version is to compare the current IP to the last script-run result which stored in the MyPubIP file.
However, in some circumstances, it may leads unexpected result.
Now, I compare the IP registered in the DNS to the current public IP for the direct result.
==================================================================================

# Announcement (2017-12-21)
I no longer use Namesilo's DNS service so I cannot help any issue for this script.

-----------------------------------------------------------------
# namesilo_ddns
Dynamic DNS record update with NameSilo. 

This is a Bash script to update Namesilo's DNS record when IP changed. Set to run this script as cronjob in your system.

Tested in Fedora 23, CentOS 7 and Ubuntu 14.04+.

## Prerequisites:

* Generate API key in the “api manager” at Namesilo

* Make sure your system have command `dig` and `xmllint`. If not, install them:

on CentOS:

```sudo yum install bind-utils libxml2```
    
on Ubuntu/Debian:

```sudo apt-get install dnsutils libxml2-utils```

## How to use:
* Download and save the Bash script.
* Modify the script, set “DOMAIN”, “HOST”, and “APIKEY” at the beginning of the script.
* Set file permission to make it executable.
* Create cronjob (optional)

## Manual test:
You should test the script to verify that actually can update the DNS record at Namesilo. 

Step 1: Create an A record in DNS Manager at Namesilo. Set it to a random IP address (not the same public IP of yours). For example:

```test.mydomain.tld     A     1.2.3.4```

Step 2: Run the script to try to update this DNS record

Step 3: Verify:

```dig +short test.domain.tld @ns1.dnsowl.com```

(you may also try other DNS server at Namesilo, e.g. `ns2.dnsowl.com`， `ns3.dnsowl.com` )

The result should show updated DNS record with your current public IP address. 
(Note: DNS record update need time to propagate to other DNS server, so if your check against other DNS server you may not see the update right away.)
