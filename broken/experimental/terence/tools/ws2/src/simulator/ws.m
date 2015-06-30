function output = ws(varargin)
global sim_params
% if there is no argument, we start the simulation without gui
output = -1;
if (nargin == 0)
% COMPILE %clc;
% COMPILE %initial_default;
% COMPILE %sim_params.gui_mode = 1;
% COMPILE %simgui;
% COMPILE %initial_gui;
% COMPILE %elseif(strcmpi(varargin{1}, 'guioff'))
    initial_default;
    sim_params.gui_mode = 0;
    ws('initial');
    ws('run_simulation');
else
    output = feval(varargin{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PUBLIC FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% then is going to initialise all time_series_stat, radio, protocol, appliation
function void = initial
global all_mote sim_params 
sim_params.event_queue = [];
sim_params.simulation_time = 0;
all_mote = []; % all mote is a structure of array
all_mote.id = 1:sim_params.total_mote;
initial_position;
initial_start_array;
% need a sperate loop because it need that all_mote to be fully initialise
for id = 1:sim_params.total_mote
    feval(sim_params.model, 'initialise', id);
    feval(sim_params.radio, 'initialise', id);
    feval(sim_params.protocol_send, 'initialise', id);
    feval(sim_params.protocol, 'initialise', id, get_start_time(id) + floor(rand*sim_params.random_start_range));
    feval(sim_params.application, 'initialise', id, get_start_time(id));
end
feval(sim_params.time_series_stat, 'initialise');
feval(sim_params.model, 'global_initialise');
feval(sim_params.radio, 'global_initialise');
feval(sim_params.protocol, 'global_initialise');
feval(sim_params.application, 'global_initialise');
void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this funciton is to create an event, called a helper function to insert to the queue
% to the global queue
% event is of a form of event_name, time, id, arg. after inserting the event, simulation 
% event loop will dequeue the event and run it
function void = insert_event(layer, event_name, time, id, event_args)
event.layer = layer;
event.event_name = event_name;
event.time = time;
event.id = id;
event.args = event_args;
insert_event2queue(event);
void = -1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% dequeue the event_queue and run
% we do not care about the time here because the important is the order of the events
% it is stupid to spin and wait slowing down the application. this is reasonable because the simulation
% is single thread.
function void = run_simulation
global sim_params
clc;
void = -1;
disp(['starting simulation']);
while ~isempty(sim_params.event_queue)
    % dequeue 
    event = sim_params.event_queue(1);
    sim_params.event_queue = sim_params.event_queue(2:length(sim_params.event_queue));
    % print event out
    % print_event(event);
    % set the simulation_time to the current event time
    sim_params.simulation_time = event.time;
    % dispatch the event to different component
    if strcmpi(event.event_name, 'pause_simulation')
        return;
    elseif sim_params.simulation_time > sim_params.simulation_duration
        dump_output_file;
        return;
    else 
        feval(event.layer, event.event_name, event.id, event.args{:});
    end
% COMPILE %if sim_params.gui_mode, drawnow;, end
end

function time = current_time
global sim_params
time = sim_params.simulation_time;

function insert_event2queue(event)
global sim_params
% note that the time we put in the event is how much time from now this event
% going to be executed. so this time have to be adjested
event.time = relative_time(event.time);

event_queue = sim_params.event_queue;
event_queue = [event event_queue];
[junk, index] = sort([event_queue.time]);
sim_params.event_queue = event_queue(index);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function time = relative_time(time_ahead)
global sim_params
time = sim_params.simulation_time + time_ahead;

function void = db(message)
void = -1;

function initial_gui
% COMPILE %gui_layer('initialise');

function void = pause_simulation
ws('insert_event', 'ws', 'pause_simulation', 0, 0, {});
void = -1;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% print the event out
function print_event(event)
if strcmpi(event.event_name, 'clock_tick')
    disp(['At time ' num2str(event.time) ', node ' num2str(event.id) ' execute ' event.event_name ' on ' event.layer]);
end

function dump_output_file
global sim_params radio_params protocol_params app_params all_mote mote_stat bs_stat gui_params link_stat protocol_stat time_series
save 'data_dump\dump.mat' sim_params radio_params protocol_params app_params all_mote mote_stat bs_stat gui_params link_stat protocol_stat time_series;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matrix = fileread(filename, width, height)
fid = fopen(filename);
column = fscanf(fid, '%f', [1 Inf]); % It has two rows now.
matrix = reshape(column, width, height)';
fclose(fid);

function void = save_start_array
global sim_params
dlmwrite(sim_params.start_predefined_file, sim_params.start_array, ' ');
void = -1;

function time = get_start_time(id)
global sim_params
time = sim_params.start_array(id);

function void = create_start_array
initial_default;
ws('initial');
save_start_array;
void = -1;

function initial_start_array
global sim_params
if sim_params.start_predefined
    sim_params.start_array = fileread(sim_params.start_predefined_file, 1, sim_params.total_mote);
else
    sim_params.start_array = floor(rand(1, sim_params.total_mote) * sim_params.random_start_range);
end

