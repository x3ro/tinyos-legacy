function plot_static(routes)
global all_mote radio_params sim_params
topology(:, 1) = all_mote.X';
topology(:, 2) = all_mote.Y';
adj_matrix = radio_params.prob_table;
range = sim_params.range;

figure;
plot(topology(:,1),topology(:,2),'r.');
hold on;
for i=1:size(adj_matrix(:,1),1)
    if i==sim_params.base_station
        continue;
    elseif routes(i) ~= -1
        line([topology(routes(i), 1),topology(i, 1)], [topology(routes(i), 2), topology(i, 2)], 'Color', [rand rand rand]);
    end
end
plot(topology(sim_params.base_station, 1), topology(sim_params.base_station, 2), 'k.');
hold off;
axis([0 range 0 range]);
