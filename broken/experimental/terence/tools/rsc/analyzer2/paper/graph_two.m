function graph_two
global rsc
% typical experiment setting
mt_good_power = 'hm_test36';
sp_good_power = 'hm_test42';
mt_congested = 'hm_test44';
paper_plot('init');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold on;
graph(mt_good_power);
handles = paper_plot('new_children');
paper_plot('set_property', handles(1), 'line', 'Marker', 'square');
paper_plot('set_property', handles(1), 'line', 'LineStyle', '--');
paper_plot('set_property', handles(1), 'line', 'LineWidth', 2);

hold on
graph(sp_good_power);
handles = paper_plot('new_children');
paper_plot('set_property', handles(1), 'line', 'Marker', '^');
paper_plot('set_property', handles(1), 'line', 'LineStyle', '-');
paper_plot('set_property', handles(1), 'line', 'LineWidth', 2);

hold on
graph(mt_congested);
handles = paper_plot('new_children');
paper_plot('set_property', handles(1), 'line', 'Marker', 'diamond');
paper_plot('set_property', handles(1), 'line', 'LineStyle', '--');
paper_plot('set_property', handles(1), 'line', 'LineWidth', 2);

legend('MT', 'SP (40%)', 'MT Congested');

function graph(tablename)
global rsc
rsc.tablename = tablename;
avg_hop('init');
avg_hop_dist('graph');
