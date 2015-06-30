set terminal pdf;
set title "Humidity Sensors at 10m elevation vs. Time"
set output "humid_10m.pdf";
set xdata time;
set xtics 60*60*6;
set grid;
set ylabel "Temp. Adjusted Humidity (%)";
set timefmt "%Y-%m-%d %H:%M:%S"
set key below
plot "newdata.txt" index 0 using 2:4 title "101 - Humidity (%)" with lines, \
"newdata.txt" index 1 using 2:4 title "102 - Humidity (%)" with lines, \
"newdata.txt" index 2 using 2:4 title "103 - Humidity (%)" with lines;

