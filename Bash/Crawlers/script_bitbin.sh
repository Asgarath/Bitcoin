#!/bin/bash

today=`date +%Y/%m/%d`
rand=`echo $RANDOM`
BASEDIR=$(dirname $0)
mkdir -p $BASEDIR/../cuaderno/$today/scrapers

tail -n1000 $BASEDIR/listado_urls_bitbin.txt > $BASEDIR/listado_urls_bitbin.aux
mv $BASEDIR/listado_urls_bitbin.aux $BASEDIR/listado_urls_bitbin.txt

wget -q -O /tmp/bitbin_auxfile1.txt.$rand  http://bitbin.it/latest_pastes.php

egrep -o "http://bitbin.it/[a-zA-Z0-9]{8}" /tmp/bitbin_auxfile1.txt.$rand | while read file
do
	getUrl=`grep "$file" $BASEDIR/listado_urls_bitbin.txt`
	findUrl=`echo $?`
	if [[ $findUrl -ne 0 ]]
	then
		echo $file >> $BASEDIR/listado_urls_bitbin.txt
		wget -q -O /tmp/bitbin_auxfile2.txt.$rand $file
		found=`cat /tmp/bitbin_auxfile2.txt.$rand | egrep -o "[^0-9A-Za-z][13][1-9A-HJ-NP-Za-km-z]{26,33}[^0-9A-Za-z]" | grep -v "193MHato6vuRXFBm45FnSnFTXeyxpByaSC" | egrep -o "[13][1-9A-HJ-NP-Za-km-z]{26,33}"`
		result=`echo $?`
		auxiliar=`echo "$found" | sort | uniq`
		if [[ $result -eq 0 ]]
		then
			echo "$auxiliar" | while read line
			do
				echo $line";"$file >> $BASEDIR/../cuaderno/$today/scrapers/bitbin_BitcoinAddress_limit.txt
			done
		fi

		found=`cat /tmp/bitbin_auxfile2.txt.$rand | egrep -o "[13][1-9A-HJ-NP-Za-km-z]{26,33}" | grep -v "193MHato6vuRXFBm45FnSnFTXeyxpByaSC" | egrep -o "[13][1-9A-HJ-NP-Za-km-z]{26,33}"`
		result=`echo $?`
		auxiliar=`echo "$found" | sort | uniq`
		if [[ $result -eq 0 ]]
		then
			echo "$auxiliar" | while read line
			do
				echo $line";"$file >> $BASEDIR/../cuaderno/$today/scrapers/bitbin_BitcoinAddress_all.txt
			done
		fi

                found=`cat /tmp/bitbin_auxfile2.txt.$rand | grep -v "<meta name=\"keywords\"" | egrep -i "bitcoin"`
                result=`echo $?`
                auxiliar=`echo "$found" | sort | uniq`
                if [[ $result -eq 0 ]]
                then
                        echo "$auxiliar" | while read line
                        do
                                echo $line";"$file >> $BASEDIR/../cuaderno/$today/scrapers/bitbin_general.txt
                        done
                fi

		rm /tmp/bitbin_auxfile2.txt.$rand
        fi
done

rm /tmp/bitbin_auxfile1.txt.$rand

