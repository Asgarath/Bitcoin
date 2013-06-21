#!/bin/bash

fecha=`date +%Y/%m/%d`

BASEDIR=$(dirname $0)
mkdir -p $BASEDIR/../cuaderno/$fecha
mkdir -p $BASEDIR/../cuaderno/$fecha/anonimizadores


#########
###TOR###
#########
wget -O /tmp/torlist_dan.txt --referer="http://www.google.com" --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" --header="Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5" --header="Accept-Language: en-us,en;q=0.5" --header="Accept-Encoding: gzip,deflate" --header="Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7" --header="Keep-Alive: 300" -dnv https://www.dan.me.uk/torlist/

cat /tmp/torlist_dan.txt | sort | uniq | while read line
do
echo $line";dan.me.uk"
done >> $BASEDIR/../cuaderno/$fecha/anonimizadores/torlist.txt

wget $H='Accept-Language: en-us,en;q=0.5' $H='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' $H='Connection: keep-alive' -U 'Mozilla/5.0 (Windows NT 5.1; rv:10.0.2) Gecko/20100101 Firefox/10.0.2' --referer=http://www.askapache.com/ "http://proxy.org/tor.shtml" -O /tmp/torlist_proxyorg.txt

html2text /tmp/torlist_proxyorg.txt | egrep "^[0-9]" | tr '\n' '#' | echo -e $(sed 's/&#x/\\x/g') | tr -d ';' | tr '#' '\n' | cut -d" " -f2 | egrep "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | while read line
do
echo $line";proxyorg"
done >> $BASEDIR/../cuaderno/$fecha/anonimizadores/torlist.txt

wget -O /tmp/torlist_resultset_blutmagie.txt http://torstatus.blutmagie.de/query_export.php/Tor_query_EXPORT.csv
wget -O /tmp/torlist_ip_blutmagie.txt http://torstatus.blutmagie.de/ip_list_all.php/Tor_ip_list_ALL.csv
wget -O /tmp/torlist_exit_blutmagie.txt http://torstatus.blutmagie.de/ip_list_exit.php/Tor_ip_list_EXIT.csv

cp /tmp/torlist_resultset_blutmagie.txt $BASEDIR/../cuaderno/$fecha/anonimizadores/
cp /tmp/torlist_ip_blutmagie.txt $BASEDIR/../cuaderno/$fecha/anonimizadores/
cp /tmp/torlist_exit_blutmagie.txt $BASEDIR/../cuaderno/$fecha/anonimizadores/

cat /tmp/torlist_resultset_blutmagie.txt | cut -d"," -f5 | egrep "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | sort | uniq | while read line
do
echo $line";blutmagie.resultset"
done >> $BASEDIR/../cuaderno/$fecha/anonimizadores/torlist.txt

cat /tmp/torlist_ip_blutmagie.txt | cut -d"," -f5 | egrep "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | sort | uniq | while read line
do
echo $line";blutmagie.ipall"
done >> $BASEDIR/../cuaderno/$fecha/anonimizadores/torlist.txt

cat /tmp/torlist_exit_blutmagie.txt | cut -d"," -f5 | egrep "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | sort | uniq | while read line
do
echo $line";blutmagie.ipexit"
done >> $BASEDIR/../cuaderno/$fecha/anonimizadores/torlist.txt

cat $BASEDIR/../cuaderno/$fecha/anonimizadores/torlist.txt | cut -d";" -f1 | sort | uniq > $BASEDIR/../cuaderno/$fecha/anonimizadores/toriplist.txt

rm /tmp/torlist*


#############
###PROXIES###
#############
i=1
num=1
rm /tmp/proxylist_vpngeeks3.txt
while [ $num -ge 1 ]
do
	url_vpngeeks=`echo "http://www.vpngeeks.com/proxylist.php?from="$i"&#pagination"`
	wget $url_vpngeeks -O /tmp/proxylist_vpngeeks.txt
	html2text /tmp/proxylist_vpngeeks.txt > /tmp/proxylist_vpngeeks2.txt
	num=`cat /tmp/proxylist_vpngeeks2.txt | egrep "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | wc -l`
	cat /tmp/proxylist_vpngeeks2.txt | egrep "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"  >> $BASEDIR/../cuaderno/$fecha/anonimizadores/proxylist_vpngeeks.txt
	cat /tmp/proxylist_vpngeeks2.txt | egrep "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | cut -d"|" -f2 | tr -d '_' >> /tmp/proxylist_vpngeeks3.txt
	let i=$i+50
	echo "###########"$i;
	echo "###########"$num;
done

cat /tmp/proxylist_vpngeeks3.txt | sort | uniq | while read line
do
echo $line";vpngeeks"
done >> $BASEDIR/../cuaderno/$fecha/anonimizadores/proxylist.txt

cat $BASEDIR/../cuaderno/$fecha/anonimizadores/proxylist.txt | cut -d";" -f1 | sort | uniq > $BASEDIR/../cuaderno/$fecha/anonimizadores/proxyiplist.txt


#Master list unifying the TOR, proxies and VPN IP lists
cat $BASEDIR/../cuaderno/$fecha/anonimizadores/*iplist.txt | sort | uniq | while read line
do
	auxlist=`grep "^$line$" $BASEDIR/../cuaderno/$fecha/anonimizadores/*iplist.txt`
	auxlist2=`echo "$auxlist" | cut -d"/" -f13 | cut -d"." -f1 | tr '\n' '|'`
	list=`echo ${auxlist2:0: -1}`
	echo $line";"$list
done > $BASEDIR/../cuaderno/$fecha/anonimizadores/masterlist.txt

rm /tmp/proxylist_*
