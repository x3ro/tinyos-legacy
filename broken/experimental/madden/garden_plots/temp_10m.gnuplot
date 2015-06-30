set terminal pdf;
set title "Humidity Temperature Sensors at 10m elevation vs. Time"
set output "temp_10m.pdf";
set xdata time;
set xtics 60*60*6;
set grid;
set ylabel "Temperature (C)";
set timefmt "%Y-%m-%d %H:%M:%S"
set key below
plot "newdata.txt" index 0 using 2:5 title "101 - Temp (C)" with lines, \
"newdata.txt" index 1 using 2:5 title "102 - Temp (C)" with lines, \
"newdata.txt" index 2 using 2:5 title "103 - Temp (C)" with lines;

