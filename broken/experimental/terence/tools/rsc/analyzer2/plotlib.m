function value = plotlib(varargin)
value = feval(varargin{:});

function output = snap_pic(pic_name)
global rsc
img_fname = [pic_name '.jpg'];
saveas(gcf, [rsc.dirpath '\' img_fname]);
delete(gcf);
core('html_print', ['<img src=''' img_fname ''' height=450 width=600><p>']);
core('print_br');

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


function pic_name = hop_contour(output)
function Z = getContourZ(x, y, z)
