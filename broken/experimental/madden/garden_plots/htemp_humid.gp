set terminal pdf;
set output "htemp.pdf";
set xdata time;

set multiplot
set noxlabel
set ylabel "Temp (C)"
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "";
set xtics 60*60*6
set nokey
set grid

set size 1,.4
set origin 0,.6
set title "Humidity Temperature Sensor vs. Time"


plot "newdata.txt" index 0 using 2:5 title "101 - Humid temp" with lines, \
"newdata.txt" index 3 using 2:5 title "104 - Humid temp" with lines, \
"newdata.txt" index 8 using 2:5 title "109 - Humid temp" with lines, \
"newdata.txt" index 9 using 2:5 title "110 - Humid temp" with lines, \
"newdata.txt" index 10 using 2:5 title "111 - Humid temp" with lines;
set size 1,.65
set origin 0,0
set key below
set xtics rotate 60*60*6
set format x "%m/%d %H:%M";
set nomxtics
set ylabel "Humidity (%)";
set title "Humidity Sensor vs. Time"
plot "newdata.txt" index 0 using 2:4 title "101 - Humid" with lines, \
"newdata.txt" index 3 using 2:4 title "104 - Humid" with lines, \
"newdata.txt" index 8 using 2:4 title "109 - Humid" with lines, \
"newdata.txt" index 9 using 2:4 title "110 - Humid" with lines, \
"newdata.txt" index 10 using 2:4 title "111 - Humid" with lines;
