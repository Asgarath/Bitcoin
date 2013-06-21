#!/bin/bash

today=`date +%Y/%m/%d`
rand=`echo $RANDOM`
BASEDIR=$(dirname $0)
mkdir -p $BASEDIR/../cuaderno/$today/scrapers

tail -n1000 $BASEDIR/listado_urls_pastebin.txt > $BASEDIR/listado_urls_pastebin.aux
mv $BASEDIR/listado_urls_pastebin.aux $BASEDIR/listado_urls_pastebin.txt

numProxies=`wc -l $BASEDIR/proxy_list_2.txt | cut -d" " -f1`
lineProxies=`echo $(( $RANDOM%$numProxies ))`
proxy=`awk "NR==$lineProxies" $BASEDIR/proxy_list_2.txt`
export http_proxy="http://$proxy"
wget -q --tries=2 --referer="http://www.google.com" --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" --header="Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5" --header="Accept-Language: en-us,en;q=0.5" --header="Accept-Encoding: gzip,deflate" --header="Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7" --header="Keep-Alive: 300" -dnv -O /tmp/pastebin_auxfile1.txt.$rand http://pastebin.com/archive

wc -l /tmp/pastebin_auxfile1.txt.$rand

egrep -o "a href=\"/[a-zA-Z0-9]{8}\"" /tmp/pastebin_auxfile1.txt.$rand | cut -d'"' -f2 | while read auxfile
do
	file=`echo "http://pastebin.com"$auxfile`
	getUrl=`grep "$file" $BASEDIR/listado_urls_pastebin.txt`
	findUrl=`echo $?`
	if [[ $findUrl -ne 0 ]]
	then
		echo $file >> $BASEDIR/listado_urls_pastebin.txt
		wget -q --tries=2 --referer="http://www.google.com" --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" --header="Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5" --header="Accept-Language: en-us,en;q=0.5" --header="Accept-Encoding: gzip,deflate" --header="Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7" --header="Keep-Alive: 300" -dnv -O /tmp/pastebin_auxfile2.txt.$rand $file

wc -l /tmp/pastebin_auxfile2.txt.$rand

		found=`cat /tmp/pastebin_auxfile2.txt.$rand | egrep -o "[^0-9A-Za-z][13][1-9A-HJ-NP-Za-km-z]{26,33}[^0-9A-Za-z]"`
		result=`echo $?`
		auxiliar=`echo "$found" | egrep -o "[13][1-9A-HJ-NP-Za-km-z]{26,33}" | sort | uniq`
		if [[ $result -eq 0 ]]
		then
			echo "$auxiliar" | while read line
			do
				echo $line";"$file >> $BASEDIR/../cuaderno/$today/scrapers/pastebin_BitcoinAddress_limit.txt
			done
		fi

		found=`cat /tmp/pastebin_auxfile2.txt.$rand | egrep -o "[13][1-9A-HJ-NP-Za-km-z]{26,33}"`
		result=`echo $?`
		auxiliar=`echo "$found" | sort | uniq`
		if [[ $result -eq 0 ]]
		then
			echo "$auxiliar" | while read line
			do
				echo $line";"$file >> $BASEDIR/../cuaderno/$today/scrapers/pastebin_BitcoinAddress_all.txt
			done
		fi

                found=`cat /tmp/pastebin_auxfile2.txt.$rand | egrep -i "bitcoin"`
                result=`echo $?`
                auxiliar=`echo "$found" | sort | uniq`
                if [[ $result -eq 0 ]]
                then
                        echo "$auxiliar" | while read line
                        do
                                echo $line";"$file >> $BASEDIR/../cuaderno/$today/scrapers/pastebin_general.txt
                        done
                fi
	
		rm /tmp/pastebin_auxfile2.txt.$rand
	fi
done

unset http_proxy

rm /tmp/pastebin_auxfile1.txt.$rand
