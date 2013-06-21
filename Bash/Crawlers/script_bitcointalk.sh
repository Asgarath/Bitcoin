#!/bin/bash

today=`date +%Y/%m/%d`
rand=`echo $RANDOM`
BASEDIR=$(dirname $0)
mkdir -p $BASEDIR/../cuaderno/$today/scrapers

tail -n100 $BASEDIR/listado_urls_bitcointalk.txt > $BASEDIR/listado_urls_bitcointalk.aux
mv $BASEDIR/listado_urls_bitcointalk.aux $BASEDIR/listado_urls_bitcointalk.txt

wget -q -O /tmp/bitcointalk_auxfile1.txt.$rand https://bitcointalk.org/index.php?action=recent

egrep -o "<a href=\"https://bitcointalk.org/index.php\?topic=[^\"]*\"" /tmp/bitcointalk_auxfile1.txt.$rand | egrep -o "https://bitcointalk.org/index.php\?topic=[^\"]*" | while read url
do
	post=`echo $url | egrep -o "https://bitcointalk.org/index.php\?topic=[0-9]*"`
	getUrl=`grep "$url" $BASEDIR/listado_urls_bitcointalk.txt`
	findUrl=`echo $?`
	if [[ $findUrl -ne 0 ]]
	then
		echo $url >> $BASEDIR/listado_urls_bitcointalk.txt
		allURL=`echo $url".0;all"`
		wget -q -O /tmp/bitcointalk_auxfile2.txt.$rand $allURL

		egrep -n -o "[^0-9A-Za-z][13][1-9A-HJ-NP-Za-km-z]{26,33}[^0-9A-Za-z]" /tmp/bitcointalk_auxfile2.txt.$rand | while read address
		do
			line=`echo $address | cut -d":" -f1`
			bitcoinAddress=`echo $address | egrep -o "[13][1-9A-HJ-NP-Za-km-z]{26,33}"`
			user=`tac /tmp/bitcointalk_auxfile2.txt.$rand | tail -n$line | grep "profile of" | head -n1 | sed 's/.*View the profile of [^>]*//g' | cut -d">" -f2 | cut -d"<" -f1`
			if [ -n "$user" ]
			then
				echo $bitcoinAddress";"$user";"$post
			fi
		done | sort | uniq > /tmp/bitcointalk_auxfile3.txt.$rand

		auxAddress=`cat /tmp/bitcointalk_auxfile3.txt.$rand | cut -d";" -f1,2 | sort | uniq | cut -d";" -f1 | sort | uniq -c | sort -nr | grep "^ *1 "`
		egrep "^$auxAddress$" /tmp/bitcointalk_auxfile3.txt.$rand | tee -a $BASEDIR/../cuaderno/$today/scrapers/bitcointalk_BitcoinAddress_limit.txt
		cat /tmp/bitcointalk_auxfile3.txt.$rand | cut -d";" -f1,2 | sort | uniq | cut -d";" -f1 | sort | uniq -c | sort -nr | grep -v "^ *1 " | awk '{print $2}' | while read line
		do
			grep "^$line;" /tmp/bitcointalk_auxfile3.txt.$rand | head -n1
		done | tee -a $BASEDIR/../cuaderno/$today/scrapers/bitcointalk_BitcoinAddress_limit.txt

		egrep -n -o "[13][1-9A-HJ-NP-Za-km-z]{26,33}" /tmp/bitcointalk_auxfile2.txt.$rand | while read address
		do
			line=`echo $address | cut -d":" -f1`
			bitcoinAddress=`echo $address | egrep -o "[13][1-9A-HJ-NP-Za-km-z]{26,33}"`
			user=`tac /tmp/bitcointalk_auxfile2.txt.$rand | tail -n$line | grep "profile of" | head -n1 | sed 's/.*View the profile of [^>]*//g' | cut -d">" -f2 | cut -d"<" -f1`
			if [ -n "$user" ]
			then
				echo $bitcoinAddress";"$user";"$post
			fi

			echo "#####" >> $BASEDIR/bitcointalk.log
			echo $bitcoinAddress";"$user";"$post";"$url >> $BASEDIR/bitcointalk.log
			egrep -n -o "[13][1-9A-HJ-NP-Za-km-z]{26,33}" /tmp/bitcointalk_auxfile2.txt.$rand >> $BASEDIR/bitcointalk.log
			echo "#####" >> $BASEDIR/bitcointalk.log
		done | sort | uniq > /tmp/bitcointalk_auxfile3.txt.$rand

		auxAddress=`cat /tmp/bitcointalk_auxfile3.txt.$rand | cut -d";" -f1,2 | sort | uniq | cut -d";" -f1 | sort | uniq -c | sort -nr | grep "^ *1 "`
		egrep "^$auxAddress$" /tmp/bitcointalk_auxfile3.txt.$rand | tee -a $BASEDIR/../cuaderno/$today/scrapers/bitcointalk_BitcoinAddress_all.txt
		cat /tmp/bitcointalk_auxfile3.txt.$rand | cut -d";" -f1,2 | sort | uniq | cut -d";" -f1 | sort | uniq -c | sort -nr | grep -v "^ *1 " | awk '{print $2}' | while read line
		do
			grep "^$line;" /tmp/bitcointalk_auxfile3.txt.$rand | head -n1
		done >> $BASEDIR/../cuaderno/$today/scrapers/bitcointalk_BitcoinAddress_all.txt

		rm /tmp/bitcointalk_auxfile2.txt.$rand
		rm /tmp/bitcointalk_auxfile3.txt.$rand
	fi
done | cut -d";" -f1-2 | sort | uniq >>  $BASEDIR/../cuaderno/$today/scrapers/bitcointalk_BitcoinAddress_users_limit.txt

cat $BASEDIR/../cuaderno/$today/scrapers/bitcointalk_BitcoinAddress_users_limit.txt | sort | uniq > $BASEDIR/../cuaderno/$today/scrapers/bitcointalk_BitcoinAddress_users_limit.aux

mv $BASEDIR/../cuaderno/$today/scrapers/bitcointalk_BitcoinAddress_users_limit.aux $BASEDIR/../cuaderno/$today/scrapers/bitcointalk_BitcoinAddress_users_limit.txt

rm /tmp/bitcointalk_auxfile1.txt.$rand
