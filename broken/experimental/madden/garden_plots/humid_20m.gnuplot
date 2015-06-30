set terminal pdf;
set title "Humidity Sensors at 20m elevation vs. Time"
set output "humid_20m.pdf";
set xdata time;
set xtics 60*60*6;
set grid;
set ylabel "Temp. Adjusted Humidity (%)";
set timefmt "%Y-%m-%d %H:%M:%S"
set key below
plot "newdata.txt" index 3 using 2:4 title "104 - Humidity (%)" with lines, \
"newdata.txt" index 4 using 2:4 title "105 - Humidity (%)" with lines, \
"newdata.txt" index 5 using 2:4 title "106 - Humidity (%)" with lines;

