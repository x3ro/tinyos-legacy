set terminal pdf;
set title "Top Light Sensor vs. Time"
set output "lighttop.pdf";
set xdata time;
set xtics 60*60*6;
set grid;
set ylabel "Light (Lux)";
set timefmt "%Y-%m-%d %H:%M:%S"
set key below
plot "newdata.txt" index 0 using 2:8 title "101 - Light Top" with linespoints, \
"newdata.txt" index 3 using 2:8 title "104 - Light Top" with linespoints, \
"newdata.txt" index 8 using 2:8 title "109 - Light Top" with linespoints, \
"newdata.txt" index 9 using 2:8 title "110 - Light Top" with linespoints, \
"newdata.txt" index 10 using 2:8 title "111 - Light Top" with linespoints;
