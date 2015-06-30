function varargout = analyzer(varargin)
[varargout{1:nargout}] = feval(varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the main function that call everything
function html_report(expname)
initialise(expname);
init_database(expname);
module = 'statistic';
feval(module, 'initialise');
result = feval(module, 'fetch_data', expname);
check_result(result);
prepare_file;
feval(module, 'general_info', result);
feval(module, 'big_loop', result);
close_file;

function initialise(expname)
global rsc
rsc.amsize = 5;
rsc.numnode = 20;
rsc.expname = expname;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% query the database
function init_database(expname);
global rsc
db = database('rsc', 'Administrator', 'blah', 'org.postgresql.Driver', 'jdbc:postgresql://localhost/rsc');
% set everything to 0
setdbprefs('NullNumberRead', '0');
setdbprefs('NullNumberWrite', '0');
setdbprefs('NullStringRead', '0');
setdbprefs('NullStringWrite', '0');
rsc.db = db;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = fetch_data(query)
global rsc
% querying the database
curs = exec(rsc.db, query);
if (curs.Cursor == 0)
    error('Error Occur when trying to query database');
end
result = [];
while 1
    cursor = fetch(curs, 1000);
    if strcmpi(cursor.Data(1), 'No Data')
        break;
    else
        result = [result; cursor.Data];    
    end   
end
%s = size(cursor.data)
%q = min(1000, s(1))
%size(cursor.data)
%while q < s(1)
%    l = min(q+1000, s(1));
%    %tmpdata = reshape(cursor.data{q+1:l,:}, [l-q, s(2)]);
%    q = l;
%    data = [data; tmpdata];
%    %disp(sprintf('%d\r', q));
%end
%curs = fetch(curs);
% save it to this messive structure
%result = cursor.Data;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = check_result(result)
if (size(result, 1) < 1)
    error('Not Enough Packets');    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function html_print(string)
global rsc
fprintf(rsc.filefid, [string]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prepare the html file
function prepare_file
global rsc
temp_dir = tempdir;
[blah1, html_dir, blah2] = fileparts(tempname);
htmlfilename = 'index.html';
fullhtmlpath = [temp_dir html_dir '\' htmlfilename];
mkdir (temp_dir, html_dir);
filefid = fopen(fullhtmlpath, 'w');
rsc.filefid = filefid;
rsc.fullhtmlpath = fullhtmlpath;
rsc.dirpath = [temp_dir html_dir];
html_print('<html><head>');
html_print('<link rel="stylesheet" href="http://www-inst.eecs.berkeley.edu/~terence/style.css">');
html_print('</head><body>');
html_print('<h2>Routing Stack Statistic Report</h2>');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close the file and open a web browser
function close_file
global rsc
filefid = rsc.filefid;
fullhtmlpath = rsc.fullhtmlpath;
html_print('</body></html>');
fclose(filefid);
status = web(fullhtmlpath,'-browser');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is going to plot the graph, save the picture and print out
% the link
% 1 is the x
% 2 is the y
% 3 is the x title
% 4 is the y title
% 5 is the graph title
% 6 is axis parameter
function data = plot_graph(output)
global rsc
% it is the plot with marker   
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
capture_pic(pic_name);

function data = plot_histogram(output)
global rsc

x = output{1};
y = output{2};
xtitle = output{3};
ytitle = output{4};
graphtitle = output{5};
pic_name = output{6};
hist(x, y);
xlabel(xtitle);
ylabel(ytitle);
title(graphtitle);
capture_pic(pic_name);

function data = plot_distance(output)
global rsc
mote = output{1};
yvalue = output{2};
[distance, yvalue, lowerbound, upperbound] = mote2distance(mote, yvalue);
xtitle = output{3};
ytitle = output{4};
graphtitle = output{5};
axis_param = [(min(output{1}) - 1) (max(output{1}) + 1) 0 max(output{2}) + 1];
pic_name = output{7};
errorbar(distance, yvalue, lowerbound, upperbound);
axis(axis_param);
xlabel(xtitle);
ylabel(ytitle);
title(graphtitle);
capture_pic(pic_name);

function data = plot_distance_scatter(output)
global rsc
mote = output{1};
yvalue = output{2};
[distance, yvalue] = mote2distance_scatter(mote, yvalue);
xtitle = output{3};
ytitle = output{4};
graphtitle = output{5};
input_axis_param = output{6};
axis_param = [min(distance) max(distance) input_axis_param(3) input_axis_param(4)];
pic_name = output{7};
scatter(distance, yvalue);
axis(axis_param);
xlabel(xtitle);
ylabel(ytitle);
title(graphtitle);
capture_pic(pic_name);



function data = plot_hop_contour(output)
global rsc
mote = output{1};
hop = output{2};
grid_distance = get_grid_distance;
[x_coors, y_coors] = get_coor(mote);
for i = 2:length(mote)
    Z(x_coors(i) / grid_distance + 1 , y_coors(i) / grid_distance  + 1) = hop(i);    
end
colormap(flipud(colormap(gray)));
contour(Z);
xtitle = output{3};
ytitle = output{4};
graphtitle = output{5};
input_axis_param = output{6};
pic_name = output{7};

xlabel(xtitle);
ylabel(ytitle);
title(graphtitle);
capture_pic(pic_name);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [distance, yvalue] = mote2distance_scatter(mote, yvalue)
distance = [];
for i = 2:length(mote)
    distance = [distance get_dist(mote(i))];
end
yvalue = yvalue(2:length(yvalue));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [x_coor, y_coor] = get_coor(id)
x_coor = fix((id - 1)/ 10) * 8;
y_coor = mod((id - 1), 10) * 8;

function distance = get_dist(id)
[x_coor, y_coor] = get_coor(id);
% assign x y value
distance = sqrt(x_coor * x_coor + y_coor * y_coor);

function grid_distance = get_grid_distance
grid_distance = 8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [X, Y, L, U] = mote2distance(mote, yvalue)
available_dist = [];
cum_sum = [];
cum_counter = [];
max_yvalue = [];
min_yvalue = [];
average_value = [];
for i = 2:length(mote)
    current_dist = get_dist(mote(i));
    if isempty(find(available_dist == current_dist)) == 1
        available_dist = [available_dist current_dist];
        index = find(available_dist == current_dist);
        cum_sum(index) = 0;
        cum_counter(index) = 0;
        max_yvalue(index) = -1e9;
        min_yvalue(index) = 1e9;
    end
    index = find(available_dist == current_dist);
    cum_sum(index) = cum_sum(index) + yvalue(i);
    cum_counter(index) = cum_counter(index) + 1;
    max_yvalue(index) = max(max_yvalue(index), yvalue(i));
    min_yvalue(index) = min(min_yvalue(index), yvalue(i));
end
original_dist = available_dist;
while ~isempty(available_dist)
    [min_value, min_index] = min(available_dist);
    available_dist = [available_dist(1:(min_index - 1)), available_dist((min_index + 1):length(available_dist))];
    index = find(original_dist == min_value);
    X = [X, min_value];
    Y = [Y, cum_sum(index) / cum_counter(index)];
    L = [L, min_yvalue(index)];
    U = [U, max_yvalue(index)];
end
L = Y - L;
U = U - Y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function capture_pic(pic_name)
global rsc
img_fname = [pic_name '.jpg'];
saveas(gcf, [rsc.dirpath '\' img_fname]);
delete(gcf);
html_print(['<img src=''' img_fname ''' height=450 width=600>']);
print_br;

function print_br 
global rsc
fprintf(rsc.filefid, '<br>'); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% extra header
function value = get_epoch(rawbyte)
global rsc
value = analyzer('fetch_data', ['select extract(epoch from timestamp ''' rawbyte{1} ''')']);
value = value{1};

function value = get_packet_id(rawbyte)
value = rawbyte{2};
function value = get_packet(rawbyte)
value = [rawbyte{3:length(rawbyte)}];

function value = get_time_stamp(epoch)
value = analyzer('fetch_data', ['select ''' '1970-01-01 00:00 GMT''' '::timestamp  + ''' num2str(epoch) ' sec''' '::interval;']);
value = value{1};


