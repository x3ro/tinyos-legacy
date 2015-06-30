set terminal png;
set output "graph.png";
set xdata time;
set timefmt "%Y-%m-%d %H:%M:%S"
plot "newdata.txt" index 0 using 2:4 title "101 - Humidity" with lines, \
"newdata.txt" index 0 using 2:5 title "101 - Temp" with lines, \
"newdata.txt" index 0 using 2:6 title "101 - Pressure" with lines, \
"newdata.txt" index 1 using 2:4 title "102 - Humidity" with lines, \
"newdata.txt" index 1 using 2:5 title "102 - Temp" with lines, \
"newdata.txt" index 1 using 2:6 title "102 - Pressure" with lines, \
"newdata.txt" index 2 using 2:4 title "103 - Humidity" with lines, \
"newdata.txt" index 2 using 2:5 title "103 - Temp" with lines, \
"newdata.txt" index 3 using 2:6 title "104 - Humidity" with lines, \
"newdata.txt" index 3 using 2:4 title "104 - Temp" with lines, \
"newdata.txt" index 3 using 2:5 title "104 - Pressure" with lines;
