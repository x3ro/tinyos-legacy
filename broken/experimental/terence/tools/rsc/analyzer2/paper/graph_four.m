function graph_four

% typical experiment setting
mt_good_power = 'hm_test36';

paper_plot('init');

global rsc
rsc.tablename = mt_good_power;
topology('init');
topology('graph');