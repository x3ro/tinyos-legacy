#set terminal pdf;
#set output "htemp.pdf";
set terminal postscript enhanced color;
set output "htemp.ps";
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
set title "Temperature Sensor vs. Time"

set style line 1 lw 4 lt 0;
set style line 2 lw 4 lt 23;
set style line 3 lw 4 lt 3;
set style line 4 lw 4 lt 1;
set style line 5 lw 4 lt 29;


plot "newdata.txt" index 1 using 2:5 title "West Side Window (2)" with lines ls 1, \
"newdata.txt" index 10 using 2:5 title "North Side Window (11)" with lines ls 2, \
"newdata.txt" index 12 using 2:5 title "Fountain (13)" with lines ls 3, \
"newdata.txt" index 13 using 2:5 title "South Side Window (15)" with lines ls 4, \
"newdata.txt" index 23 using 2:5 title "South East Corner (25)" with lines ls 5;
set size 1,.65
set origin 0,0
set key below
set xtics rotate 60*60*6
set format x "%m/%d %H:%M";
set nomxtics
set ylabel "Humidity (%)";
set title "Humidity Sensor vs. Time"
plot "newdata.txt" index 1 using 2:4 title "West Side Window (2)" with lines ls 1, \
"newdata.txt" index 10 using 2:4 title "North Side Window (11)" with lines ls 2, \
"newdata.txt" index 12 using 2:4 title "Fountain (13)" with lines ls 3, \
"newdata.txt" index 13 using 2:4 title "South Side Window (15)" with lines ls 4, \
"newdata.txt" index 23 using 2:4 title "South East Corner (25)" with lines ls 5;
