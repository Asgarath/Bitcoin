#!/bin/bash

###Usage: script_aggregation_1_file.sh "user" "password"
###Version: 9
###Aggregation method 1 - Linking of inputs
###It is necessary to include two parameters, the user and password of the database.

###Bitcoin addresses not used don't form part of this first analysis

###Command to determine % analyzed:
#date +'%Y/%m/%d %H:%M:%S'; comprobacionTotal="14515692"; echo "Total transactions: "$comprobacionTotal; comprobacionUltimaTransaction=`tac results_aggregation_1/logfile_file.log | grep "tx_id in txin:" | head -n1 | grep -o "[0-9]*"`; echo "Last transaction: "$comprobacionUltimaTransaction; comprobacionPosicion=`grep -n "^$comprobacionUltimaTransaction;" txid_txin_aggregation.txt | cut -d":" -f1`; echo "Position in transaction file: "$comprobacionPosicion; comprobacionInputsAnalizados=`head -n$comprobacionPosicion txid_txin_aggregation.txt | cut -d";" -f2 | awk '{SUM+=$1} END {print SUM}'`; echo "Inputs analyzed: "$comprobacionInputsAnalizados; comprobacionTotalInputs="30086387"; echo "Total inputs: "$comprobacionTotalInputs; comprobacionPorcentage=`echo "scale=2; $comprobacionInputsAnalizados*100/$comprobacionTotalInputs" | bc -l | sed 's/^\./0\./g'`; echo "Percentage inputs analyzed: "$comprobacionPorcentage"%"

###Example:
#2013/06/02 22:18:44
#Total transactions: 14515692
#Last transaction: 12899458
#Position in transaction file: 20154
#Inputs analyzed: 2940362
#Total inputs: 30086387
#Percentage inputs analyzed: 9.77%

###Init data
###In the logFile will be stored the stdout from the script. It consists on basic data to determine how much info has been analyzed
###In the errorFile will be stored the stderror from the script. It allows to detect if there is any problem with the database or the program
user=$1
password=$2
BASEDIR=$(dirname $0)
mkdir $BASEDIR/results_aggregation_1
resultFile=`echo $BASEDIR"/results_aggregation_1/address_aggregation_1.txt"`
rm $resultFile
touch $resultFile
logFile=`echo $BASEDIR"/results_aggregation_1/logfile_file.log"`
errorFile=`echo $BASEDIR"/results_aggregation_1/errorfile_file.log"`

echo "DATE INIT: `date`" > $logFile
echo "DATE INIT: `date`" > $errorFile

###Create transaction file if it does not exist
if [ ! -f $BASEDIR/../txid_txin_aggregation.txt ]
then
	mysql -u $user --password="$password" -e "select tx_id, count(*) from txin group by tx_id order by count(*) desc" btg | tr '\t' ';' > $BASEDIR/../txid_txin_aggregation.txt
	grep -v ";1$" $BASEDIR/../txid_txin_aggregation.txt > $BASEDIR/../txid_txin_aggregation_several_inputs.txt
fi

ident=0
cat $BASEDIR/../txid_txin_aggregation_several_inputs.txt | grep -v "tx_id" | while read line
do
	txid=`echo $line | cut -d";" -f1`
	echo "################################"
	echo "tx_id in txin: $txid"
	echo "tx_id in txin: "$txid >> $errorFile

	auxiliar1=`mysql -u $user --password="$password" -e "select txout_id from txin where tx_id='$txid'" btg | grep -v "txout_id" | sort | uniq`
	auxiliar2=`echo "$auxiliar1" | tr '\n' ','`
	auxgrep=`echo "("${auxiliar2:0: -1}")"`
	auxiliarKeys1=`mysql -u $user --password="$password" -e "select pubkey_id from txout where txout_id in $auxgrep" btg | grep -v "pubkey" | sort | uniq`
	auxiliarKeys2=`echo "$auxiliarKeys1" | tr '\n' '|'`
	auxgrepKeys=`echo "("${auxiliarKeys2:0: -1}")"`

    foundAll=`egrep "^$auxgrepKeys;" $resultFile`
    found=`echo "$foundAll" | cut -d";" -f1`

	if [ -z "$found" ]
	then
###Case where all the pubkeys involved have not been analyzed before
#The data and a new identifier is added to the aggregation file
		echo "num pubkey found in file EQUAL 0"
		echo "NEW IDENT: $ident"
		auxiliarKeys3=`echo "$auxiliarKeys1" | tr '\n' ','`
		auxsqlKeys=`echo "("${auxiliarKeys3:0: -1}")"`
		mysql -u $user --password="$password" -e "select * from pubkey where pubkey_id in $auxsqlKeys" btg | grep -v "pubkey" | tr '\t' ';' | while read bitcoinAddress
		do
			echo $bitcoinAddress";"$ident >> $resultFile
		done
		let ident=$ident+1
	else
        number=`echo "$found" | wc -l`
        if [[ $number -eq 1 ]]
        then
###Case where one pubkeys involved has been analyzed before
			echo "num pubkey found in file EQUAL 1"

#Stablish the value of the analyzed pubkey as reference
       	    initIdent=`echo "$foundAll" | cut -d";" -f4`
			echo "only IDENT FOUND: $initIdent"
#Add the reference identifier to the pubkeys involved in the current transaction 
            auxiliarKeys3=`echo "$auxiliarKeys1" | egrep -v "^$found$" | tr '\n' ','`
            if [ ! -z "$auxiliarKeys3" ]
            then
       	        auxsqlKeys=`echo "("${auxiliarKeys3:0: -1}")"`
               	mysql -u $user --password="$password" -e "select * from pubkey where pubkey_id in $auxsqlKeys" btg | grep -v "pubkey" | tr '\t' ';' | while read bitcoinAddress
                do
					echo $bitcoinAddress";"$initIdent >> $resultFile
				done
       	    fi
		else
###Case where several pubkeys involved have been analyzed before
			echo "num pubkey found in file GREATER THAN 1"

#Stablish the value of one of these analyzed pubkeys as reference
			initIdent=`echo "$foundAll" | head -n1 | cut -d";" -f4`
			echo "first IDENT FOUND: $initIdent"
#Get list of identifiers belonging to the pubkeys found
       	    auxChangeValues=`echo "$foundAll" | cut -d";" -f4 | sort | uniq`
            auxValues=`echo "$auxChangeValues" | tr '\n' '|'`
            auxGrepValues=`echo "("${auxValues:0: -1}")"`
#Change the identifier of the pubkeys that have the same identifier as the pubkeys found to the reference value
            egrep ";$auxGrepValues$" $resultFile | cut -d";" -f1-3 | sort | uniq | while read line
       	    do
                echo $line";"$initIdent >> $BASEDIR/results_aggregation_1/address_aggregation_1v8.aux
            done
            egrep -v ";$auxGrepValues$" $resultFile >> $BASEDIR/results_aggregation_1/address_aggregation_1v8.aux
       	    mv $BASEDIR/results_aggregation_1/address_aggregation_1v8.aux $resultFile
#Add the reference identifier to the pubkeys involved in the current transaction 
            auxiliarKeys3=`echo "$auxiliarKeys1" | egrep -v "^$found$" | tr '\n' ','`
			if [ ! -z "$auxiliarKeys3" ]
            then
	            auxsqlKeys=`echo "("${auxiliarKeys3:0: -1}")"`
        	    mysql -u $user --password="$password" -e "select * from pubkey where pubkey_id in $auxsqlKeys" btg | grep -v "pubkey" | tr '\t' ';' | while read address
       	        do
               	    echo $address";"$initIdent >> $resultFile
                done
			fi
		fi
	fi
echo "################################"
echo ""
echo ""
echo ""
done >> $logFile 2>> $errorFile


#How many different entities have been stablished from the Bitcoin transactions
cut -d";" -f4 $resultFile | sort | uniq | wc -l

#How many Bitcoin addresses have been used as sources in Bitcoin transactions
cut -d";" -f1 $resultFile | sort | uniq | wc -l

#Bitcoin addresses not used don't form part of this first analysis

echo "DATE FI: `date`" > $logFile
echo "DATE FI: `date`" > $errorFile
