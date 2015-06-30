set terminal pdf;
set title "Humidity Temperature Sensors at 30m elevation vs. Time"
set output "temp_30m.pdf";
set xdata time;
set xtics 60*60*6;
set grid;
set ylabel "Temperature (C)";
set timefmt "%Y-%m-%d %H:%M:%S"
set key below
plot "newdata.txt" index 6 using 2:5 title "107 - Temp (C)" with lines, \
"newdata.txt" index 7 using 2:5 title "108 - Temp (C)" with lines, \
"newdata.txt" index 8 using 2:5 title "109 - Temp (C)" with lines;

