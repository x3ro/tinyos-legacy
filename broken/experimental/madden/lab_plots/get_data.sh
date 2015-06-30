#!/bin/bash
export PGPASSWORD=tiny
psql -h berkeley16-desk -U tele task < runqueries.sql
scp Administrator@berkeley16-desk:/tmp/data.txt .
sed "s/,/ /g" data.txt > newdata.txt
perl insert-breaks.pl < newdata.txt > data.txt
mv data.txt newdata.txt
gnuplot htemp_humid.gp
convert htemp.ps htemp.jpg