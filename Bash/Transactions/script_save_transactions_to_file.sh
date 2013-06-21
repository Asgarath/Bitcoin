#!/bin/bash

yesterday=`date +%Y/%m/%d --date=yesterday`
BASEDIR=$(dirname $0)

tx=$1

txHash=`echo $tx | sed 's#,#,\n#g' | grep "hash" | cut -d'"' -f4 | grep -v "^$" | head -n1`
echo $txHash
echo $tx | sed 's#,#,\n#g' > /tmp/aux_transaction_$txHash.txt

#Timestamp of the transaction
txTime=`cat /tmp/aux_transaction_$txHash.txt | grep "time" | cut -d":" -f2 | cut -d"," -f1`

#IP
txIP=`cat /tmp/aux_transaction_$txHash.txt | grep "relayed_by" | cut -d'"' -f4`

#Number of inputs
txVIN=`cat /tmp/aux_transaction_$txHash.txt | grep "vin_sz" | cut -d":" -f2 | cut -d"," -f1`

#Inputs
#HACER ALGO ESPECIAL
txInputs=`echo $tx | tr ']' '[' | cut -d"[" -f2`
#txInputs=`cat /tmp/aux_transaction_$txHash.txt | grep "inputs" | cut -d"[" -f2 | cut -d"]" -f1`

#Number of outputs
txVOUT=`cat /tmp/aux_transaction_$txHash.txt | grep "vout_sz" | cut -d":" -f2 | cut -d"," -f1`

#Outputs
#HACER ALGO ESPECIAL
txOut=`echo $tx | tr ']' '[' | cut -d"[" -f4`
#txOut=`cat /tmp/aux_transaction_$txHash.txt | grep "out" | cut -d"[" -f2 | cut -d"]" -f1`

#Version
txVersion=`cat /tmp/aux_transaction_$txHash.txt | grep "ver" | cut -d":" -f2 | cut -d"," -f1`

#Index
txIndex=`echo $tx | tr ']' '[' | cut -d"[" -f1,3,5 | sed 's#,#,\n#g' | grep "tx_index" | cut -d":" -f2 | cut -d"," -f1`

#Size
txSize=`cat /tmp/aux_transaction_$txHash.txt | grep "size" | cut -d":" -f2 | cut -d"," -f1`

#BlockHeight
txBlockHeight=`cat /tmp/aux_transaction_$txHash.txt | grep "block_height" | cut -d":" -f2 | cut -d"," -f1`

#Formato simple
#time;hash;IP;vIN;inputs;vout;out;version
echo $txTime";"$txHash";"$txIP";"$txVIN";"$txInputs";"$txVOUT";"$txOut";"$txVersion >> $BASEDIR/../cuaderno/$yesterday/transacciones/simple.txt

#Formato completo
#time;hash;IP;vIN;inputs;vout;out;version;index;size;blockheight
echo $txTime";"$txHash";"$txIP";"$txVIN";"$txInputs";"$txVOUT";"$txOut";"$txVersion";"$txIndex";"$txSize";"$txtxBlockHeight >> $BASEDIR/../cuaderno/$yesterday/transacciones/completa.txt

rm /tmp/aux_transaction_$txHash.txt
