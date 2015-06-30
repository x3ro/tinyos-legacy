function output = gui_layer(varargin)
output = feval(varargin{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function void = settings
global sim_params radio_params protocol_params;
% Gui Parameter
gui_layer('add_param_entry', 'sim_params', '      -- GENERAL --', 3, 0 , '');
gui_layer('add_param_entry', 'sim_params', 'total_mote', 1, [1, +Inf], 'How many motes do you want?');
gui_layer('add_param_entry', 'sim_params', 'range', 0, [1, +Inf], 'How big is the simulation?');
gui_layer('add_param_entry', 'sim_params', 'protocol', ...
2, {'broadcast', 'mrp', 'mrp_shortest_path', 'shortest_path' }, 'Which protocol do you want to use?');
gui_layer('add_param_entry', 'sim_params', 'application', 2, {'collect_data', 'dummy_send_data', 'blank_component'}, 'Which application do you want to use?');
gui_layer('add_param_entry', 'sim_params', 'topology_style', 2, {'random', 'row and column'}, 'What topology do you want the motes to have?');
gui_layer('add_param_entry', 'sim_params', 'simulation_duration', 1, [1, +Inf], 'How long do you the simulation to be?');
gui_layer('add_param_entry', 'sim_params', 'bs_clock_tick_interval', 1, [1, +Inf], 'How often do you want the base station clock to be ticked?');
gui_layer('add_param_entry', 'sim_params', 'node_clock_tick_interval', 1, [1, +Inf], 'How ofter do you want other notes clock to be ticked?');
gui_layer('add_param_entry', 'sim_params', 'base_station', 1, [1, sim_params.range], 'Which note act as a base station');

gui_layer('add_param_entry', 'radio_params', '      -- PROB RADIO --', 3, 0, '');
gui_layer('add_param_entry', 'radio_params', 'prob_predefined', 1, [0 1], 'Probability defined?');
gui_layer('add_param_entry', 'radio_params', 'prob_predefined_file', 4, [], 'What is the name of the probability file?');

gui_layer('add_param_entry', 'protocol_params', '      -- PROTOCOL --', 3, 0, '');
gui_layer('add_param_entry', 'protocol_params', 'route_data_ratio', 1, [1 +Inf], 'How many data packet to send');
void = -1;


function void = initialise
global gui_params
textbox_display('Welcome To Wireless Network Simulator');
% need to set up other parameters and stuffn
gui_params.stage = 1;
stage_parser;
upload_params;
void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = default_mote_text(id, moteX, moteY, message)
global gui_params
[x, y] = text_offset(moteX, moteY);
valid = check_valid(gui_params.drawn_text, id);
if valid
    h = gui_params.drawn_text(id);
    set(h, 'Position', [x y], 'String', message);
else
    gui_params.drawn_text(id) = text('Position', [x y], 'String', message, 'Parent', gui_params.maingui.ocean, 'FontSize', 8);
end
void = -1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = parent_line_withno_menu(id, childX, childY, parentX, parentY)
global gui_params
% the only time it is valid when it is not equal to invalid handle
valid = check_valid(gui_params.drawn_parent, id);
color = choose_color(id);
% if this is valid, i set the properties
if valid
    h = gui_params.drawn_parent(id);
    set(h, 'XData', [childX parentX], 'YData', [childY parentY], 'Color', color);
else
    gui_params.drawn_parent(id) = line('XData', [childX parentX], 'YData', [childY parentY], 'LineStyle', '-', ...
        'Parent', gui_params.maingui.ocean, 'Color', color);
end
void = -1;

function void = parent_line_with_menu(id, childX, childY, parentX, parentY, varargin)
global gui_params
% the only time it is valid when it is not equal to invalid handle
valid = check_valid(gui_params.drawn_parent, id);
color = choose_color(id);


% if this is valid, i set the properties
if valid
    h = gui_params.drawn_parent(id);
    set(h, 'XData', [childX parentX], 'YData', [childY parentY], 'Color', color);
else    
    menu = uicontextmenu('Parent', gui_params.maingui.figure);
    for i = 1:2:length(varargin)/2
        label = varargin{i};
        func_str = varargin{i + 1};
        uimenu(menu, 'Label', label, 'Callback', func_str);
    end
    gui_params.drawn_parent(id) = line('XData', [childX parentX], 'YData', [childY parentY], 'LineStyle', '-', ...
        'Parent', gui_params.maingui.ocean, 'Color', color, 'UIContextMenu', menu);
end
void = -1;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = square_mote_withno_menu(id, x, y)
global gui_params
[XData, YData] = calculate_corner(x, y);
valid = check_valid(gui_params.drawn_mote, id);
color = choose_color(id);
if valid
    h = gui_params.drawn_mote(id);
    set(h, 'XData', XData, 'YData', YData, 'FaceColor', color, 'EdgeColor', 'none', 'UIContextMenu', menu);
else
    gui_params.drawn_mote(id) = patch('XData', XData, 'YData', YData, 'FaceColor', color, 'EdgeColor', 'none', ...
        'Parent', gui_params.maingui.ocean, 'LineWidth', 2);
end
void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function void = refresh
global gui_params
line([0 0], [0 0], 'parent', gui_params.maingui.ocean);
drawnow;
void = -1;

function void = close_gui
global gui_params
delete(gui_params.maingui.figure);
void = -1;

function picked_color = choose_color(index)
color_choice = ['m', 'r', 'g', 'b', 'k'];
color_index = mod(index, length(color_choice)) + 1;
picked_color = color_choice(color_index);

function valid = check_valid(drawn, id)
valid = (drawn(id) ~= -1);

function [newx, newy] = text_offset(moteX, moteY)
global gui_params
newx = moteX + gui_params.mote_height;
newy = moteY + gui_params.mote_width;

function [XData, YData] = calculate_corner(x, y)
global gui_params
width = gui_params.mote_height;
height =  gui_params.mote_height;
leftX = x - width / 2;
bottomY = y - height / 2;
rightX = x + width / 2;
topY = y + height / 2;
XData = [leftX, leftX, rightX, rightX];
YData = [bottomY, topY, topY, bottomY];

function void = textbox_display(message)
global gui_params
set(gui_params.maingui.textbox, 'String', message);
void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function void = stage_parser
global gui_params
stage = gui_params.stage;
if stage == 1
    change_button_text(1, 'Initialise Node');
    change_button_text(2, '');
    change_button_text(3, '');
elseif stage == 2
    change_button_text(1, 'Initialise Node');
    change_button_text(2, 'Start Simulation');
    change_button_text(3, '');
elseif stage == 3
    change_button_text(1, 'ReInitialise Node');
    change_button_text(2, 'Pause Simulation');
    change_button_text(3, '');
elseif stage == 4
    change_button_text(1, 'ReInitialise Node');
    change_button_text(2, '');
    change_button_text(3, 'Plot Data');
elseif stage == 5
    change_button_text(1, 'ReInitialise Node');
    change_button_text(2, 'Continue Simulation');
    change_button_text(3, 'Plot Data');
    
end
void = -1;

function void = change_button_text(which_button, msg)
global gui_params
button_handle = getfield(gui_params.maingui, ['button' num2str(which_button)]);
set(button_handle, 'String', msg);
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function void = clear_ocean
global gui_params sim_params
range = sim_params.range;
old_ocean = gui_params.maingui.ocean;
position = get(old_ocean, 'Position');
units = get(old_ocean, 'Units');
delete(old_ocean);
gui_params.maingui.ocean = axes('parent', gui_params.maingui.figure, 'Units', units, 'XLim', [0 range], 'YLim', [0 range], ...
    'XTick', [], 'YTick', [], 'Position', position, 'DrawMode', 'fast');
set(gui_params.maingui.figure, 'Units', 'pixels');
set(gui_params.maingui.ocean, 'Units', 'pixels');
gui_params.drawn_mote = zeros(1, sim_params.total_mote) - 1;
gui_params.drawn_text = zeros(1, sim_params.total_mote) - 1;
gui_params.drawn_parent = zeros(1, sim_params.total_mote) - 1;
gui_params.mote_width = sim_params.range / 50;
gui_params.mote_height = sim_params.range / 100;
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function void = add_param_entry(glob_name, var_name, type, choice, message)
global gui_params
void = -1;
entry.glob_name = glob_name;
entry.var_name = var_name;
entry.type = type;
entry.choice = choice;
entry.message = message;
try gui_params.all_params;
catch
    gui_params.all_params = [entry]; 
    return;
end
gui_params.all_params = [gui_params.all_params entry];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function upload_params
global gui_params
set(gui_params.maingui.parameters, 'String', { gui_params.all_params.var_name });

function void = select_param(index)
global gui_params sim_params radio_params protocol_params app_params
entry = gui_params.all_params(index);
msg = [entry.message range_msg(entry.type, entry.choice)];
textbox_display(msg);
if entry.type ~= 3
    value = eval([entry.glob_name '.' entry.var_name]);
    set(gui_params.maingui.param_value, 'String', num2str(value));
end
void = -1;

function msg = range_msg(type, choice)
msg = [];
if type == 0
    msg = [' Input a real between ' num2str(choice(1)) ' and ' num2str(choice(2))];
elseif type == 1
    msg = [' Input a int between ' num2str(choice(1)) ' and ' num2str(choice(2))];
elseif type == 2
    msg = [' Choices are: '];
    choice_length = length(choice);
    for i = 1:(choice_length - 1)
        msg = [msg choice{i} ', '];
    end
    msg = [msg ' and ' choice{choice_length}];
elseif type == 4
    msg = [' Input a String'];
end

% 0 is real
% 1 is int
% 2 is a choice str
% 3 is a seperator
% 4 is any string

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function void = submit_value(index, str_value)
global gui_params
current_entry = gui_params.all_params(index);
% convert the value
value = convert_value(current_entry.type, str_value);
% check if valid
valid = check_valid_input(current_entry.type, current_entry.choice, value);
% if not valid, display error message
if ~valid
    display_error(current_entry.type, current_entry.choice);
else
% if valid, set the value to global value
    set_current_value(current_entry.glob_name, current_entry.var_name, value);
    textbox_display([current_entry.var_name ' is set to ' str_value '!!!']);
end
void = -1;

function value = convert_value(type, str_value)
global gui_params
if type == 0 | type == 1
    value = str2double(str_value);
elseif type == 2 | type == 3 | type == 4
    value = str_value;
end

function valid = check_valid_input(type, choice, value)
if type == 0
    valid = (value >= choice(1) & value <= choice(2));
elseif type == 1
    within_choice = (value >= choice(1) & value <= choice(2));
    isint = (value == fix(value));
    valid = (within_choice & isint);
elseif type == 2
    valid = ~isempty(find(strcmpi(choice, value)));
elseif type == 3
    valid = 0;
elseif type == 4
    valid = 1;
end

function display_error(type, choice)
msg = [' Invalid! Again,' range_msg(type, choice)];
textbox_display(msg);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function void = set_current_value(glob_name, var_name, value)
% this is super dumb man, i cannot think of any generatl function that could do something like eval('ab') = 2
% assignin cannot do global variable.. so...
global sim_params radio_params protocol_params app_params gui_params
new_struct = setfield(eval(glob_name), var_name, value);
if strcmpi(glob_name, 'sim_params')
    sim_params = new_struct;
elseif strcmpi(glob_name, 'radio_params')
    radio_params = new_struct;
elseif strcmpi(glob_name, 'protocol_params')
    protocol_params = new_struct;
elseif strcmpi(glob_name, 'app_params')
    app_params = new_struct;
elseif strcmpi(glob_name, 'gui_params')
    gui_params = new_struct;
end
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%