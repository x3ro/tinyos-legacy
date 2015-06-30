function varargout = vis_gui(varargin)
% VIS_GUI M-file for vis_gui.fig
%      VIS_GUI, by itself, creates a new VIS_GUI or raises the existing
%      singleton*.
%
%      H = VIS_GUI returns the handle to a new VIS_GUI or the handle to
%      the existing singleton*.
%
%      VIS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIS_GUI.M with the given input arguments.
%
%      VIS_GUI('Property','Value',...) creates a new VIS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before vis_gui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vis_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help vis_gui

% Last Modified by GUIDE v2.5 13-Jul-2003 03:28:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @vis_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @vis_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before vis_gui is made visible.
function vis_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to vis_gui (see VARARGIN)

% Choose default command line output for vis_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes vis_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% set checkboxes according to current values
global VIS;
set(handles.pos_real,'Value',VIS.show.real_pos);
set(handles.pos_calc,'Value',VIS.show.calc_pos);
set(handles.pos_error,'Value',VIS.show.pos_error);
set(handles.mag_contour, 'Value', VIS.show.mag_contour);

set(handles.routing_tree,'Value',VIS.show.route_tree);
set(handles.show_crumb, 'Value', VIS.show.crumb_trails);
%set(handles.route_messages,'Value',VIS.show.route_messages);


set(handles.real_agent_pos, 'Value', VIS.show.real_agent_pos);
set(handles.calc_agent_pos, 'Value', VIS.show.calc_agent_pos);

set(handles.agent_heading, 'Value', VIS.show.agent_heading);

% FIXME: for the demo, hide things that aren't implemented
set(handles.agent_heading, 'Visible', 'off');
%set(handles.pos_calc, 'Visible', 'off');
%set(handles.pos_error, 'Visible', 'off');



% --- Outputs from this function are returned to the command line.
function varargout = vis_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% check the real_route flag, and do something reasonable based on
% whether we are showing real or calculated node positions 
function fix_real_route
global VIS;
if VIS.show.real_pos || ~VIS.show.calc_pos
  %if VIS.show.real_route == 0
  %  VIS.flag.route_tree_updated = 1;
  %end
  VIS.show.real_route = 1;
else
  %if VIS.show.real_route == 1
  %  VIS.flag.route_tree_updated = 1;
  %end
  VIS.show.real_route = 0;
end


% --- Executes on button press in pos_real.
function pos_real_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.real_pos = get(hObject,'Value');
fix_real_route;


% --- Executes on button press in pos_calc.
function pos_calc_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.calc_pos = get(hObject,'Value');
fix_real_route;


% --- Executes on button press in pos_error.
function pos_error_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.pos_error = get(hObject,'Value');


% --- Executes on button press in routing_tree.
function routing_tree_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.route_tree = get(hObject,'Value');


% --- Executes on button press in route_messages.
function route_messages_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.route_messages = get(hObject,'Value');


% --- Executes on button press in show_crumb.
function show_crumb_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.crumb_trails = get(hObject,'Value');


% --- Executes on button press in mag_contour.
function mag_contour_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.mag_nodes = get(hObject,'Value');
VIS.show.mag_contour = get(hObject,'Value');


% --- Executes on button press in real_agent_pos.
function real_agent_pos_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.real_agent_pos = get(hObject,'Value');


% --- Executes on button press in calc_agent_pos.
function calc_agent_pos_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.calc_agent_pos = get(hObject,'Value');


% --- Executes on button press in agent_heading.
function agent_heading_Callback(hObject, eventdata, handles)
global VIS;
VIS.show.agent_heading = get(hObject,'Value');


% --- Executes on button press in pause_vis.
function pause_vis_Callback(hObject, eventdata, handles)
global VIS;
if get(hObject,'Value') == 1
    stopVisTimer;
else
    startVisTimer;
end


% --- Executes during object creation, after setting all properties.
function ranging_data_CreateFcn(hObject, eventdata, handles)
set(hObject,'BackgroundColor','white');

% --- Executes on button press in ranging_data.
function ranging_data_Callback(hObject, eventdata, handles)
drawRangingInfo( get(hObject,'String') );


% --- Executes during object creation, after setting all properties.
function anchor_data_CreateFcn(hObject, eventdata, handles)
set(hObject,'BackgroundColor','white');


function anchor_data_Callback(hObject, eventdata, handles)
drawAnchorInfo( get(hObject,'String') );


