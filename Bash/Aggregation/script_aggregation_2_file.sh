#!/bin/bash

###Usage: script_aggregation_2_file.sh "user" "password"
###Version: 3
###Aggregation method 2 - Linking of outputs
###It is necessary to include two parameters, the user and password of the database.

###Bitcoin addresses not used don't form part of this first analysis

###Command to determine % analyzed:
#date +'%Y/%m/%d %H:%M:%S'; comprobacionTotal="13061821"; echo "Total transactions: "$comprobacionTotal; comprobacionUltimaTransaccion=`tac results_aggregation_2/logfile_file.log | grep "tx_id in txout:" | head -n1 | grep -o "[0-9]*"`; echo "Last transaction: "$comprobacionUltimaTransaccion; comprobacionPosicion=`egrep -n "^$comprobacionUltimaTransaccion$" txid_txout_aggregation_double_output.txt | cut -d":" -f1`; echo "Position in transaction file: "$comprobacionPosicion; comprobacionPorcentage=`echo "scale=2; $comprobacionPosicion*100/$comprobacionTotal" | bc -l | sed 's/^\./0\./g'`; echo "Percentage transactions analyzed: "$comprobacionPorcentage"%"

###Example:
#2013/06/14 22:18:44
#Total transactions: 13061821
#Last transaction: 1167652
#Position in transaction file: 268016
#Percentage inputs analyzed: 2,05%

###Init data
###In the logFile will be stored the stdout from the script. It consists on basic data to determine how much info has been analyzed
###In the errorFile will be stored the stderror from the script. It allows to detect if there is any problem with the database or the program
user=$1
password=$2
BASEDIR=$(dirname $0)
mkdir $BASEDIR/results_aggregation_2
resultFile=`echo $BASEDIR"/results_aggregation_2/address_aggregation_2.txt"`
rm $resultFile
touch $resultFile
logFile=`echo $BASEDIR"/results_aggregation_2/logfile_file.log"`
errorFile=`echo $BASEDIR"/results_aggregation_2/errorfile_file.log"`

echo "DATE INIT: `date`" > $logFile
echo "DATE INIT: `date`" > $errorFile

###Create transaction file if it does not exist
if [ ! -f $BASEDIR/../txid_txout_aggregation.txt ]
then
        mysql -u $user --password="$password" -e "select tx_id, count(*) from txout group by tx_id order by count(*) desc" btg | tr '\t' ';' > $BASEDIR/../txid_txout_aggregation.txt
fi

if [ ! -f $BASEDIR/../txid_txout_aggregation_double_output.txt ]
then
	cat $BASEDIR/../txid_txout_aggregation.txt | grep ";2$" | cut -d";" -f1 > $BASEDIR/../txid_txout_aggregation_double_output.txt
fi

ident=0
cat $BASEDIR/../txid_txout_aggregation_double_output.txt | grep -v "tx_id" | while read txid
do

	echo "################################"
	echo "tx_id in txout: "$txid
	echo "tx_id in txout: "$txid >> $errorFile

#Obtain pubkey of the outputs
	auxiliarData=`mysql -u $user --password="$password" -e "select pubkey_id,txout_value from txout where tx_id='$txid'" btg | tr '\t' ';' | grep -v "pubkey" | sort | uniq`

#Find the output with more decimals (less 0s)
	auxiliarValue=`echo "$auxiliarData" | cut -d";" -f2 | rev | sort | tail -n1 | rev`
	auxiliarOutput=`echo "$auxiliarData" | egrep -i ";$auxiliarValue$" | head -n1`
	auxiliarKeys0=`echo "$auxiliarOutput" | cut -d";" -f1 | sort | uniq`	

#Obtain pubkays of the inputs involved
	auxiliar1=`mysql -u $user --password="$password" -e "select txout_id from txin where tx_id='$txid'" btg | grep -v "txout_id" | sort | uniq`
	auxiliar2=`echo "$auxiliar1" | egrep -v "^$" | tr '\n' ','`
	auxgrep=`echo "("${auxiliar2:0: -1}")"`
	auxiliarKeys1=`mysql -u $user --password="$password" -e "select pubkey_id from txout where txout_id in $auxgrep" btg | grep -v "pubkey" | sort | uniq`

#Check if any of the pubkeys involved has been analyzed before
	auxiliarKeys2=`echo -e "$auxiliarKeys0""\\n""$auxiliarKeys1" | egrep -v "^$" | tr '\n' '|'`
	auxgrepKeys=`echo "("${auxiliarKeys2:0: -1}")"`
	
	foundAll=`egrep "^$auxgrepKeys;" $resultFile`
	found=`echo "$foundAll" | cut -d";" -f1`
	if [ -z "$found" ]
	then
###Case where all the pubkeys involved have not been analyzed before
#The data and a new identifier is added to the aggregation file	
		echo "inputs or outputs in file EQUAL 0"
		echo "NEW IDENT: $ident"

		auxiliarKeys3=`echo -e "$auxiliarKeys0""\\n""$auxiliarKeys1" | egrep -v "^$" | tr '\n' ','`
		if [ ! -z "$auxiliarKeys3" ]
		then
			auxsqlKeys=`echo "("${auxiliarKeys3:0: -1}")"`
			mysql -u $user --password="$password" -e "select * from pubkey where pubkey_id in $auxsqlKeys" btg | grep -v "pubkey" | tr '\t' ';' | while read bitcoinAddress
			do
				echo $bitcoinAddress";"$ident >> $resultFile
			done
			let ident=$ident+1
		fi
	else
		number=`echo "$found" | wc -l`
		if [[ $number -eq 1 ]]
		then
###Case where one pubkeys involved has been analyzed before
			echo "inputs or outputs in file EQUAL 1"

#Stablish the value of the analyzed pubkey as reference
			initIdent=`echo "$foundAll" | cut -d";" -f4`
			echo "only IDENT FOUND: $initIdent"
#Add the reference identifier to the pubkeys involved in the current transaction 
			auxiliarKeys3=`echo -e "$auxiliarKeys0""\\n""$auxiliarKeys1" | egrep -v "^$found$" | egrep -v "^$" | tr '\n' ','`
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
			echo "inputs or outputs in file GREATER THAN 1"

#Stablish the value of one of these analyzed pubkeys as reference			
            initIdent=`echo "$foundAll" | head -n1 | cut -d";" -f4`
			echo "first IDENT FOUND: $initIdent"
#Get list of identifiers belonging to the pubkeys found
			auxChangeValues=`echo "$foundAll" | cut -d";" -f4 | sort | uniq`
            auxValues=`echo "$auxChangeValues" | egrep -v "^$" | tr '\n' '|'`
            auxGrepValues=`echo "("${auxValues:0: -1}")"`
#Change the identifier of the pubkeys that have the same identifier as the pubkeys found to the reference value
            egrep ";$auxGrepValues$" $resultFile | cut -d";" -f1-3 | sort | uniq | while read line
            do
                echo $line";"$initIdent >> $BASEDIR/results_aggregation_2/address_aggregation_2.aux
            done
            egrep -v ";$auxGrepValues$" $resultFile >> $BASEDIR/results_aggregation_2/address_aggregation_2.aux
            mv $BASEDIR/results_aggregation_2/address_aggregation_2.aux $resultFile
#Add the reference identifier to the pubkeys involved in the current transaction
            auxiliarKeys3=`echo -e "$auxiliarKeys0""\\n""$auxiliarKeys1" | egrep -v "^$found$" | egrep -v "^$" | tr '\n' ','`
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

echo "DATE FI: `date`" > $logFile
echo "DATE FI: `date`" > $errorFile
