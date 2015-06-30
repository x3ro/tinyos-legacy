#!/bin/bash
export PGPASSWORD=tiny
psql -h cspc-14-2.berkeley.edu garden tele < runqueries.sql
scp Administrator@cspc-14-2.berkeley.edu:/tmp/data.txt .
sed "s/,/ /g" data.txt > newdata.txt
perl insert-breaks.pl < newdata.txt > data.txt
mv data.txt newdata.txt
gnuplot htemp_humid.gp
gnuplot htemp_ptemp.gp
gnuplot humid_10m.gnuplot
gnuplot humid_20m.gnuplot
gnuplot humid_30m.gnuplot

gnuplot temp_10m.gnuplot
gnuplot temp_20m.gnuplot
gnuplot temp_30m.gnuplot

gnuplot pressure.gnuplot
gnuplot light_bot.gnuplot
gnuplot light_top.gnuplot
