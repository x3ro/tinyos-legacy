#!/bin/sh
echo Deleting old files
./delall
../reset
sleep 3
TMP=/tmp/matchbox.$$
bash full.sh | tee $TMP
echo
TMP2=$TMP.nnl
sed $'s/[\x0d]//g' $TMP > $TMP2
diff -u $TMP2 normal.output
dr=$?
/bin/rm -f $TMP $TMP2
test "$dr" -eq 1 && exit 2
exit 0
