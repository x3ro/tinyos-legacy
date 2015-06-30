function output = plot_data(varargin)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% written by guide
if nargin == 0  % LAUNCH GUI
	fig = openfig(mfilename,'reuse');	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
    handles = initialise(handles);
    guidata(fig, handles);
	if nargout > 0
		output = fig;
	end
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
	try
		output = feval(varargin{:}); % FEVAL switchyard
	catch
		disp(lasterr);
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% this is just going to give the choices of graph to display in the choices 
%% drop down menu
function handles = initialise(handles)

plot_name = app_lib('get_stat_funcs');
%% set the choices to what application and blah provide
set(handles.choices, 'String', plot_name);
%% set the file name field's visiblity to off
set(handles.file_name, 'Visible', 'off');


% --------------------------------------------------------------------
function output = graph_provided_Callback(h, eventdata, handles, varargin)
output = -1;


% --------------------------------------------------------------------
function output = choices_Callback(h, eventdata, handles, varargin)
output = -1;



% --------------------------------------------------------------------
function output = data_dump_Callback(h, eventdata, handles, varargin)
output = -1;
if get(h, 'Value') == 1
    set(handles.file_name, 'Visible', 'on')
else
    set(handles.file_name, 'Visible', 'off');
end


% --------------------------------------------------------------------
function output = file_name_Callback(h, eventdata, handles, varargin)
output = -1;

% --------------------------------------------------------------------
function output = plot_Callback(h, eventdata, handles, varargin)
output = -1;
function_name = get_function_name(handles);
is_data_dump = get_data_dump(handles);
file_name = get_file_name(handles);
output_data = plot_graph(function_name);
if (is_data_dump)
    dump_data(file_name, output_data);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function dump_data(file_name, output_data)
dlmwrite(file_name, output_data, ' ');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%% plot data
%% a stands for application layer, h stands for histogram, p stands for plot
function data = plot_graph(function_name)
output = app_lib(function_name);
data = plot_graph_helper(output);

function data = plot_graph_helper(output)
if output{7} == 0
    % it is the plot with marker   
    x = output{1};
    y = output{2};
    xtitle = output{3};
    ytitle = output{4};
    graphtitle = output{5};
    axis_param = output{6};
    scatter_or_plot = output{8};
    if strcmp(scatter_or_plot, 'plot')
        plot(x, y, '--rs', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'g', 'MarkerSize', 10);
    elseif strcmp(scatter_or_plot, 'scatter')
        scatter(x, y);
    end
    axis(axis_param);
    xlabel(xtitle);
    ylabel(ytitle);
    title(graphtitle);
    if isempty(x) | isempty(y), data = -1;, return;, end
    data(1, :) = x;
    data(2, :) = y;
elseif output{7} == 1
    x = output{1};
    y = output{2};
    xtitle = output{3};
    ytitle = output{4};
    graphtitle = output{5};
    axis_param = output{6};
    plot(x, y, 'r');
    axis(axis_param);
    xlabel(xtitle);
    ylabel(ytitle);
    title(graphtitle);
    if isempty(x) | isempty(y), data = -1;, return;, end
    data(1, :) = x;
    data(2, :) = y;
elseif output{7} == 2
    z = output{1};
    xtitle = output{2};
    ytitle = output{3};
    ztitle = output{4};
    surf(z);
    colormap hsv;
    xlabel(xtitle);
    ylabel(ytitle);
    zlabel(ztitle);
    if isempty(z), data = -1, return;, end
    data = z;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%% just get the name and type of the function selected
function name = get_function_name(handles)
selected_index = get(handles.choices, 'Value');
choices = get(handles.choices, 'String');
name = choices{selected_index};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%% return 1 if the data dumb option is on
function bool = get_data_dump(handles)
bool = get(handles.data_dump, 'Value');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%% return the file name for data dump
function file_name = get_file_name(handles)
file_name = get(handles.file_name, 'String');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function modified_data = filter_invalid_data(data)
modified_data = [];
for i = 1:length(data)
    if isfinite(data(i))
        modified_data = [ modified_data data(i)];
    end
end
