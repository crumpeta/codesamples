#!/bin/bash


FM_LINES=$$

ssh $ivat "grep FormMail /opt/apps/apache/logs/access-combined.log > /tmp/$FM_LINES"
scp $ivat:/tmp/$FM_LINES ~/tmp/

grep "POST /cgi/FormMail.pl" ~/tmp/$FM_LINES > ~/tmp/${FM_LINES}-post
grep -v 68.236.182.179 ~/tmp/${FM_LINES}-post > ~/tmp/${FM_LINES}-nova
grep -v " 200 " ~/tmp/${FM_LINES}-nova > ~/tmp/${FM_LINES}-302s

cut -d' '  -f1,4 ~/tmp/${FM_LINES}-302s.txt | cut -d'[' -f2,1 --output-delimiter=' ' | awk '{print $2, $1;}' | cut -d: -f 1,4 --output-delimiter=' ' | cut -d' ' -f1 | uniq -c

# foreach server

## get the logs

# filter out the successful uses of form

# print a report


