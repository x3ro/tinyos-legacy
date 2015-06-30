function graph_three
global rsc
% typical experiment setting
mt_high_power = 'hm_test33';
mt_low_power = 'hm_test36';
mt_low_congested = 'hm_test44';
paper_plot('init');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hold on;
subplot(3, 1, 1);
graph(mt_high_power);

subplot(3, 1, 2);
graph(mt_low_power);

subplot(3, 1, 3);
graph(mt_low_congested);


function graph(tablename)
global rsc
rsc.tablename = tablename;
stability('init');
stability('graph');
