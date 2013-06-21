#!/bin/bash

blockFile=$1
BASEDIR=$(dirname $0)

cat $blockFile | sed 's/^[[:space:]]*//' | sed 's#^"tx":\[##g' | sed 's#},{"time":#},\n{"time":#g' | grep '{"time"' >> $blockFile.aux

cat $blockFile.aux | while read line
do
$BASEDIR/script_save_transactions_to_file.sh "$line"
done

rm $blockFile.aux

