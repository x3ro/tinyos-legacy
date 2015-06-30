function graph_one
global rsc
% typical experiment setting
mt_good_power = 'hm_test36';
sp_good_power = 'hm_test42';
mt_congested = 'hm_test44';
paper_plot('init');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hold on;
graph(mt_good_power);
handles = paper_plot('new_children');
paper_plot('set_property', handles(1), 'line', 'Marker', 'none');
paper_plot('set_property', handles(1), 'line', 'LineStyle', ':');
paper_plot('set_property', handles(2), 'line', 'Marker', 's');
paper_plot('set_property', handles(2), 'line', 'LineStyle', '-');
paper_plot('set_property', handles, 'line', 'Color', [1 0 0]);
main_lines(1) = handles(2);

hold on;
graph(sp_good_power);
handles = paper_plot('new_children');
paper_plot('set_property', handles(1), 'line', 'Marker', 'none');
paper_plot('set_property', handles(1), 'line', 'LineStyle', ':');
paper_plot('set_property', handles(2), 'line', 'Marker', 'd');
paper_plot('set_property', handles(2), 'line', 'LineStyle', '-');
paper_plot('set_property', handles, 'line', 'Color', [0 1 0]);
main_lines(2) = handles(2);

hold on;
graph(mt_congested);
handles = paper_plot('new_children');
paper_plot('set_property', handles(1), 'line', 'Marker', 'none');
paper_plot('set_property', handles(1), 'line', 'LineStyle', ':');
paper_plot('set_property', handles(2), 'line', 'Marker', 'v');
paper_plot('set_property', handles(2), 'line', 'LineStyle', '-');
paper_plot('set_property', handles, 'line', 'Color', [0 0 1]);
main_lines(3) = handles(2);

legend(main_lines, 'MT', 'SP (40%)', 'MT Congested');

hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function graph(tablename)
global rsc
rsc.tablename = tablename;
data_generated('init');
data_received('init');
success_rate('init');
success_rate_distance('init');
success_rate_distance('graph');




