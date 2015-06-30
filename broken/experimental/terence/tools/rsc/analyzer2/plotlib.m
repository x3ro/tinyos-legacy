function value = plotlib(varargin)
value = feval(varargin{:});

function output = snap_pic(pic_name)
global rsc
img_fname = [pic_name '.jpg'];
saveas(gcf, [rsc.dirpath '\' img_fname]);
delete(gcf);
core('html_print', ['<img src=''' img_fname ''' height=450 width=600><p>']);
core('print_br');output = -1;

function pic_name = graph(output)
global rsc
% 1 is the x
% 2 is the y
% 3 is the x title
% 4 is the y title
% 5 is the graph title
% 6 is axis parameter
x = output{1};
y = output{2};
xtitle = output{3};
ytitle = output{4};
graphtitle = output{5};
axis_param = output{6};
pic_name = output{7};
plot(x, y, '--rs', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'g', 'MarkerSize', 10);
axis(axis_param);
xlabel(xtitle);
ylabel(ytitle);
title(graphtitle);
void = -1;
function pic_name = plot_freq(output)global rsc% 1 is the x% 2 is the y% 3 is the x title% 4 is the y title% 5 is the graph title% 6 is axis parametery = output{1};xtitle = output{2};ytitle = output{3};graphtitle = output{4};pic_name = output{6};[y, x] = hist(y, output{5});plot(x, y);xlabel(xtitle);ylabel(ytitle);title(graphtitle);void = -1;
function pic_name = distance(output)global rscbasestation_index = find(rsc.nodesID == rsc.basestationID);coor = rsc.coor;input_motes = output{1};nodes_indes = [];for i = 1:length(input_motes), nodes_indes = [nodes_indes find(input_motes(i) == rsc.nodesID)];, enddistance = sqrt((coor(nodes_indes, 1) - coor(basestation_index, 1)) .^ 2 + (coor(nodes_indes, 2) - coor(basestation_index, 2)) .^ 2);xtitle = output{3};ytitle = output{4};graphtitle = output{5};input_axis_param = output{6};axis_param = [min(distance) max(distance) input_axis_param(1) input_axis_param(2)];pic_name = output{7};%scatter(distance, output{2}, '+');unique_distance = unique(distance);for i = 1:length(unique_distance)    same_distance_index = find(unique_distance(i) == distance);    values = output{2};    y(i) = mean(values(same_distance_index));    std_values(i) = std(values(same_distance_index));end% plot(unique_distance, y);errorbar(unique_distance, y, std_values);% scatter(distance, output{2}, 's');axis(axis_param);xlabel(xtitle);ylabel(ytitle);title(graphtitle);
function pic_name = hop_contour(output)global rscgrid = output{1};hops = output{2};graphtitle = output{3};pic_name = output{4};%% since contour always plot something from (1, 1), that's why we need to add one to itX = grid(:, 1) + 1;Y = grid(:, 2) + 1;Z = getContourZ(X, Y, hops);plot(grid(:, 1) + 1, grid(:, 2) + 1, 'r.');hold onbasestation_index = find(rsc.nodesID == rsc.basestationID);plot(grid(basestation_index, 1) + 1, grid(basestation_index, 2) + 1, 'k.');hold on%colormap(flipud(colormap(gray)));[C, h] = contour(Z', min(rsc.final_hop):0.5:max(rsc.final_hop));h = clabel(C, h);set(h, 'Color', [.3 .2 .2]);title(graphtitle);
function Z = getContourZ(x, y, z)Z = [];for i = 1:length(x)    Z(x(i), y(i)) = z(i);end

