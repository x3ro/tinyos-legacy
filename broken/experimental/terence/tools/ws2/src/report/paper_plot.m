function output = paper_plot(varargin)
output = feval(varargin{:});

function output = plot_all
plot_simulation('Cumulative_Hop_Count');
plot_simulation('Yield_Versus_Hop');
plot_simulation('Effort_Versus_Hop');
plot_simulation('Actual_Path_Reliablity_Versus_Hop');
plot_simulation('Stability_Over_Time');


function plot_simulation(func_name)
load shortest_path_route_stack_threshold_6
plot_data('plot_graph', func_name);
hold on
load min_trans_route_stack
plot_data('plot_graph', func_name);
hold on
load dsdv_shortest_path
plot_data('plot_graph', func_name);
hold on
load broadcast_100on80_2000sec
plot_data('plot_graph', func_name);
hold on
load 100nodes80_min_trans_route_table_20_2000time
plot_data('plot_graph', func_name);
hold on
load shortest_path_route_stack_threshold_2
plot_data('plot_graph', func_name);
hold on
beautify(['SP w/ Loss Threshold'; 'MT'; 'DSDV'; 'BroadCast'; 'MT w/ Table Management'; 'SP w/ Tight Threshold';  ]);

function void = beautify(graph_name_list)
void = -1;
marker_list = ['+' 'o' '*' '.' 'x' 's' 'd' '^' 'v' '>' '<' 'p' 'h'];
linestyle_list = {'-', '--', ':', '-.'};
line_handle_list = get(gca, 'Children');
if length(graph_name_list) ~= length(line_handle_list)
  disp(['graph name list length not matched']);
  return;
end
  
for i = 1:length(line_handle_list)
  handle = line_handle_list(i);
  set(handle, 'Marker', marker_list(mod(i, length(marker_list))));
  set(handle, 'LineStyle', linestyle_list{mod(i, length(linestyle_list))});
end
legend(graph_name_list(:))







