#!/bin/bash

###############
###FUNCTIONS###
###############

#Recursive function to get the blocks from yesterday
yesterdayBlock() {
	local localHashBlock=$1
	wget -q http://blockchain.info/rawblock/$localHashBlock -O /tmp/aux_block_$localHashBlock.txt
	localTimeBlock=`grep "time" /tmp/aux_block_$localHashBlock.txt | head -n1 | cut -d":" -f2 | cut -d"," -f1`
	localDateBlock=`date +'%Y-%m-%d' --date="@${localTimeBlock}"`
	localhashPreviousBlock=`grep "prev_block" /tmp/aux_block_$localHashBlock.txt | head -n1 | cut -d'"' -f4`

	if [ "$today" == "$localDateBlock" ]
	then
		yesterdayBlock $localhashPreviousBlock
	elif [ "$yesterday" == "$localDateBlock" ]
	then
		yesterdayBlock $localhashPreviousBlock
		$BASEDIR/script_extract_transactions_from_block.sh "/tmp/aux_block_$localHashBlock.txt"	
	fi
	rm /tmp/aux_block_$localHashBlock.txt 
	return 0
}

###############
###MAIN CODE###
###############

#Create the folder where we will save the transactions
yesterday=`date +%Y/%m/%d --date=yesterday`
BASEDIR=$(dirname $0)
mkdir $BASEDIR/../cuaderno/$yesterday/transacciones

#Save the date from yesterday 
today=`date +'%Y-%m-%d'`
yesterday=`date +'%Y-%m-%d' --date=yesterday`
yesterdaySlash=`date +%Y/%m/%d --date=yesterday`

#Obtain latest block from blockchain.info
wget -q http://blockchain.info/latestblock -O /tmp/aux_latestblock.txt

#Get the hash of the last block
hashLastBlock=`grep "hash" /tmp/aux_latestblock.txt | head -n1 | cut -d'"' -f4`

#Obtain info from the last block
wget -q http://blockchain.info/rawblock/$hashLastBlock -O /tmp/aux_block_$hashLastBlock.txt

hashPreviousBlock=`grep "prev_block" /tmp/aux_block_$hashLastBlock.txt | cut -d'"' -f4`

#Call recursive function
yesterdayBlock $hashPreviousBlock

rm /tmp/aux_latestblock.txt
rm /tmp/aux_block_$hashLastBlock.txt


###Different IPs used
cat $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/simple.txt | cut -d";" -f3 | sort | uniq -c | sort -nr | awk '{print $2 ";" $1}' > $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/ip_transacciones_diferentes.txt


###IPs of anoniymizing services
cat $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/simple.txt | cut -d";" -f3 | sort | uniq | while read line
do
	list=`grep "^$line;" $BASEDIR/../cuaderno/$yesterdaySlash/anonimizadores/masterlist.txt`
	result=`echo $?`
	if [ "$result" == "0" ]
	then
		echo $list
	fi
done > $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/ip_transacciones_anonimizadoras.txt


#Anonymizing transactions
cat $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/ip_transacciones_anonimizadoras.txt | cut -d";" -f1 | sort | uniq | while read line
do
	num=`grep ";$line;" $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/simple.txt | wc -l`
	echo $line";"$num
done > $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/transacciones_anonimizadoras.txt


#Statistics
totalTrans=`wc -l $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/simple.txt | cut -d" " -f1`
echo "total_transactions;"$totalTrans >> $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/estadisticas_transacciones.txt

numberAnoTrans=`cat $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/transacciones_anonimizadoras.txt | cut -d";" -f2 | awk '{SUM=SUM+$1} END {print SUM}'`
echo "number_anonymizing_transactions;"$numberAnoTrans >> $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/estadisticas_transacciones.txt

percentage=`echo "scale=2; $numberAnoTrans*100/$totalTrans" | bc -l | sed 's/^\./0\./g'`
echo "percentage_anonymizing_transactions;"$percentage >> $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/estadisticas_transacciones.txt

totalIPs=`wc -l $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/ip_transacciones_diferentes.txt | cut -d" " -f1`
echo "total_ips;"$totalIPs >> $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/estadisticas_transacciones.txt

numberAnoIPs=`wc -l $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/ip_transacciones_anonimizadoras.txt | cut -d" " -f1`
echo "number_anonymizing_ips;"$numberAnoIPs >> $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/estadisticas_transacciones.txt

percentageIPs=`echo "scale=2; $numberAnoIPs*100/$totalIPs" | bc -l | sed 's/^\./0\./g'`
echo "percentage_anonymizing_IPs;"$percentageIPs >> $BASEDIR/../cuaderno/$yesterdaySlash/transacciones/estadisticas_transacciones.txt
