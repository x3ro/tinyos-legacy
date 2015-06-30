function simgui(varargin)
global gui_params
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% written by guide
if nargin == 0  % LAUNCH GUI
	fig = openfig(mfilename,'reuse');
	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
    gui_params.maingui = handles;
    gui_params.stage = 1;
    guidata(fig, handles);

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    try
		feval(varargin{:}); % FEVAL switchyard
	catch
		disp(lasterr);
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --------------------------------------------------------------------
function parameters_Callback(h, eventdata, foreign_handles, varargin)
gui_layer('select_param', get(h, 'Value'));

% --------------------------------------------------------------------
function param_value_Callback(h, eventdata, foreign_handles, varargin)

% --------------------------------------------------------------------
function varargout = change_Callback(h, eventdata, foreign_handles, varargin)
global gui_params
gui_layer('submit_value', get(gui_params.maingui.parameters, 'Value'), get(gui_params.maingui.param_value, 'String'));

% --------------------------------------------------------------------
function varargout = textbox_Callback(h, eventdata, foreign_handles, varargin)

% --------------------------------------------------------------------
function varargout = button1_Callback(h, eventdata, foreign_handles, varargin)
global gui_params
gui_params.stage = 2;
gui_layer('stage_parser');
gui_layer('clear_ocean');
gui_layer('textbox_display', ['Initialising .....']);
ws('initial');
gui_layer('refresh');
gui_layer('textbox_display', ['Done Initialising!']);

% --------------------------------------------------------------------
function varargout = button2_Callback(h, eventdata, foreign_handles, varargin)
global gui_params
stage = gui_params.stage;
if stage == 3 
    gui_params.stage = 5;
    gui_layer('textbox_display', ['Simulation Paused!']);
    ws('pause_simulation');

elseif stage == 5 | stage == 2
    gui_params.stage = 3;
    gui_layer('stage_parser');
    gui_layer('textbox_display', ['Simulation Running .....']);
    ws('run_simulation');
    % if this is pause, stage will become 5, so leave it alone
    % if it is not paused, then stage should be 4
    if gui_params.stage ~= 5 % it this is not paused or simulation done
        gui_params.stage = 4;
        gui_layer('textbox_display', ['Simulation Finished!']); 
    end
end

gui_layer('stage_parser');
gui_layer('refresh');

% --------------------------------------------------------------------
function varargout = button3_Callback(h, eventdata, foreign_handles, varargin)
global gui_params
stage = gui_params.stage;

if stage == 4 | stage == 5
    plot_data;
end
gui_layer('stage_parser');
gui_layer('refresh');


% --------------------------------------------------------------------
function varargout = quit_Callback(h, eventdata, foreign_handles, varargin)
gui_layer('close_gui');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


