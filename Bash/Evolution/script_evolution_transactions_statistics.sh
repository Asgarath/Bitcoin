#!/bin/bash

BASEDIR=$(dirname $0)
mkdir $BASEDIR/results_transaction_evolution_statistics
resultFile=`echo $BASEDIR"/results_transaction_evolution/transactions"`
resultFile2=`echo $BASEDIR"/results_transaction_evolution_several_inputs/transactions_several_inputs"`
resultFile3=`echo $BASEDIR"/results_transaction_evolution_two_outputs/transactions_two_outputs"`
fileAll=`echo $BASEDIR"/results_transaction_evolution_statistics/transactions_all_statistics.txt"`
fileInput=`echo $BASEDIR"/results_transaction_evolution_statistics/transactions_input_statistics.txt"`
fileOutput=`echo $BASEDIR"/results_transaction_evolution_statistics/transactions_output_statistics.txt"`
logFile=`echo $BASEDIR"/results_transaction_evolution_statistics/logfile.log"`
errorFile=`echo $BASEDIR"/results_transaction_evolution_statistics/errorfile.log"`

rm $fileAll
rm $fileInput
rm $fileOutput
touch $fileAll
touch $fileInput
touch $fileOutput

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
			allTrans=`wc -l $resultFile.$year.$month.txt | cut -d" " -f1`
			inputTrans=`wc -l $resultFile2.$year.$month.txt | cut -d" " -f1`
			outputTrans=`wc -l $resultFile3.$year.$month.txt | cut -d" " -f1`
			echo $year"-"$month";"$allTrans >> $fileAll
			echo $year"-"$month";"$inputTrans >> $fileInput
			echo $year"-"$month";"$outputTrans >> $fileOutput
		fi

		echo $endData > /tmp/auxiliarEndData.txt
		initData=`cat /tmp/auxiliarEndData.txt`
	done
done >> $logFile 2>> $errorFile

echo "DATE END: `date`" >> $logFile