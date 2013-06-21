#!/bin/bash

user=$1
pass=$2
BASEDIR=$(dirname $0)
mkdir $BASEDIR/results_transaction_evolution
mkdir $BASEDIR/results_transaction_evolution_several_inputs
mkdir $BASEDIR/results_transaction_evolution_two_outputs
rm $BASEDIR/results_transaction_evolution/transactions.*
rm $BASEDIR/results_transaction_evolution_several_inputs/transactions_several_inputs.*
rm $BASEDIR/results_transaction_evolution_two_outputs/transactions_two_outputs.*
resultFile=`echo $BASEDIR"/results_transaction_evolution/transactions"`
resultFile2=`echo $BASEDIR"/results_transaction_evolution_several_inputs/transactions_several_inputs"`
resultFile3=`echo $BASEDIR"/results_transaction_evolution_two_outputs/transactions_two_outputs"`
logFile=`echo $BASEDIR"/results_transaction_evolution/logfile.log"`
errorFile=`echo $BASEDIR"/results_transaction_evolution/errorfile.log"`

echo "DATE INIT: `date`" > $logFile
echo "DATE INIT: `date`" > $errorFile


initData=`date +%s --date="2009/01/01 00:00:00"`
echo $initData > /tmp/auxiliarEndData.txt

echo "2009
2010
2011
2012
2013" | while read year
do
		initData=`cat /tmp/auxiliarEndData.txt`
	echo "01
	02
	03
	04
	05
	06
	07
	08
	09
	10
	11
	12" | while read month
	do
		endData=`date +%s --date="$year/$month/01 00:00:00"`

		echo $initData $endData

		bloc=`echo $year"."$month`
		echo $bloc >> $errorFile
		if [ "$bloc" != "2009.01" ] && [ "$bloc" != "2013.05" ] && [ "$bloc" != "2013.06" ] && [ "$bloc" != "2013.07" ] && [ "$bloc" != "2013.08" ] && [ "$bloc" != "2013.09" ] && [ "$bloc" != "2013.10" ] && [ "$bloc" != "2013.11" ] && [ "$bloc" != "2013.12" ]
		then
			auxBlock1=`mysql -u $user --password="$pass" -e "select block_id from block where block_nTime>='$initData' and block_nTime<'$endData'" btg | grep -v "block_id" | sort | uniq`
			auxBlock2=`echo "$auxBlock1" | tr '\n' ','`
			auxsqlBlock=`echo "("${auxBlock2:0: -1}")"`

			auxTrans1=`mysql -u $user --password="$pass" -e "select tx_id from block_tx where block_id in $auxsqlBlock" btg | grep -v "tx_id" | sort | uniq`

			echo "$auxTrans1" > /tmp/evolution_transactions_file_aux.txt
			num=`wc -l /tmp/evolution_transactions_file_aux.txt | cut -d" " -f1`
			i=0
			while [ $num -gt 0 ]
			do
				wc -l /tmp/evolution_transactions_file_aux.txt
				auxTrans2=`head -n10000 /tmp/evolution_transactions_file_aux.txt | tr '\n' ','`
				auxsqlTrans=`echo "("${auxTrans2:0: -1}")"`
	
				mysql -u $user --password="$pass" -e "select tx_id, count(*) from txin where tx_id in $auxsqlTrans group by tx_id order by count(*) desc" btg | tr '\t' ';' > $resultFile.$year.$month.$i.txt
				mysql -u $user --password="$pass" -e "select tx_id, count(*) from txout where tx_id in $auxsqlTrans group by tx_id having count(*)=2" btg | tr '\t' ';' > $resultFile3.$year.$month.$i.txt
				sed '1,10000d' /tmp/evolution_transactions_file_aux.txt > /tmp/evolution_transactions_file_aux2.txt
				mv /tmp/evolution_transactions_file_aux2.txt /tmp/evolution_transactions_file_aux.txt
				num=`wc -l /tmp/evolution_transactions_file_aux.txt | cut -d" " -f1`
				let i=$i+1
			done
			cat $resultFile.$year.$month.*.txt | awk -F';' '{print $2";"$1}' | grep -v "count" | sort -nr > $resultFile.$year.$month.txt
			cat $resultFile3.$year.$month.*.txt | awk -F';' '{print $2";"$1}' | grep -v "count" | sort -nr > $resultFile3.$year.$month.txt
			cat $resultFile.$year.$month.*.txt | awk -F';' '{print $2";"$1}' | grep -v "count" | grep -v "^1;" | sort -nr > $resultFile2.$year.$month.txt
		fi

		echo $endData > /tmp/auxiliarEndData.txt
		initData=`cat /tmp/auxiliarEndData.txt`
	done
done >> $logFile 2>> $errorFile

echo "DATE END: `date`" >> $logFile