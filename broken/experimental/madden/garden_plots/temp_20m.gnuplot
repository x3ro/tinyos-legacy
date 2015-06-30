set terminal pdf;
set title "Humidity Temperature Sensors at 20m elevation vs. Time"
set output "temp_20m.pdf";
set xdata time;
set xtics 60*60*6;
set grid;
set ylabel "Temperature (C)";
set timefmt "%Y-%m-%d %H:%M:%S"
set key below
plot "newdata.txt" index 3 using 2:5 title "104 - Temp (C)" with lines, \
"newdata.txt" index 4 using 2:5 title "105 - Temp (C)" with lines, \
"newdata.txt" index 5 using 2:5 title "106 - Temp (C)" with lines;

