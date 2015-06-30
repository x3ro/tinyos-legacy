set terminal pdf;
set title "Bottom Light Sensor vs. Time"
set output "lightbot.pdf";
set xdata time;
set xtics 60*60*6;
set grid;
set ylabel "Light (Lux)";
set timefmt "%Y-%m-%d %H:%M:%S"
set key below
plot "newdata.txt" index 0 using 2:9 title "101 - Light (bot)" with linespoints pointsize 1, \
"newdata.txt" index 3 using 2:9 title "104 - Light (bot)" with linespoints pointsize 1, \
"newdata.txt" index 8 using 2:9 title "109 - Light (bot)" with linespoints pointsize 1, \
"newdata.txt" index 9 using 2:9 title "110 - Light (bot)" with linespoints pointsize 1, \
"newdata.txt" index 10 using 2:9 title "111 - Light (bot)" with linespoints pointsize 1;
