set terminal pdf;
set title "Humidity Sensors at 30m elevation vs. Time"
set output "humid_30m.pdf";
set xdata time;
set xtics 60*60*6;
set grid;
set ylabel "Temp. Adjusted Humidity (%)";
set timefmt "%Y-%m-%d %H:%M:%S"
set key below
plot "newdata.txt" index 6 using 2:4 title "107 - Humidity (%)" with lines, \
"newdata.txt" index 7 using 2:4 title "108 - Humidity (%)" with lines, \
"newdata.txt" index 8 using 2:4 title "109 - Humidity (%)" with lines;

