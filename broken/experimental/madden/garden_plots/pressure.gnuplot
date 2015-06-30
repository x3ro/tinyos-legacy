set terminal pdf;
set title "Pressure vs. Time"
set output "pressure.pdf";
set xdata time;
set xtics 60*60*6;
set grid;
set ylabel "Pressure (mbar)";
set timefmt "%Y-%m-%d %H:%M:%S"
set key below
plot "newdata.txt" index 0 using 2:6 title "101 - Pressure" with lines, \
"newdata.txt" index 3 using 2:6 title "104 - Pressure" with lines, \
"newdata.txt" index 8 using 2:6 title "109 - Pressure" with lines, \
"newdata.txt" index 9 using 2:6 title "110 - Pressure" with lines, \
"newdata.txt" index 10 using 2:6 title "111 - Pressure" with lines;
