function varargout = botControl(varargin)
% BOTCONTROL Application M-file for botControl.fig
%    FIG = BOTCONTROL launch botControl GUI.
%    BOTCONTROL('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.0 17-Jun-2002 05:23:24

if nargin == 0  % LAUNCH GUI

    global TURN
    global SPEED
    global DIR
    TURN=20;
    SPEED=0;
    DIR=128;
    
	fig = openfig(mfilename,'reuse');

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);

	if nargout > 0
		varargout{1} = fig;
	end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
	catch
		disp(lasterr);
	end

end


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.

% --------------------------------------------------------------------
function varargout = forwardButton_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.forwardButton.
FORWARD=128;
global TURN
global SPEED
global DIR
DIR = FORWARD;
packetData = buildDataPacket(SPEED,FORWARD,TURN);
routePackets(2,botPacket(packetData));
packetData

% --------------------------------------------------------------------
function varargout = reverseButton_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.reverseButton.
REVERSE=0;
global TURN
global SPEED
global DIR
DIR = REVERSE;
packetData = buildDataPacket(SPEED,REVERSE,TURN);
routePackets(2,botPacket(packetData));
packetData

% --------------------------------------------------------------------
function varargout = offButton_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.offButton.
OFF=0;
global TURN
global SPEED
global DIR
SPEED=OFF;
packetData = buildDataPacket(OFF,DIR,TURN);
routePackets(2,botPacket(packetData));
packetData

% --------------------------------------------------------------------
function varargout = straightButton_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.straightButton.
STRAIGHT=20;
global TURN
global SPEED
global DIR
TURN=STRAIGHT;
packetData = buildDataPacket(SPEED,DIR,STRAIGHT);
routePackets(2,botPacket(packetData));
packetData

% --------------------------------------------------------------------
function varargout = sendCmdsButton_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.setCmdsButton.
FORWARD=128;
REVERSE=0;
global TURN
global SPEED
global DIR
speed(1)=str2num(get(handles.speed1Edit,'String'));
speed(2)=str2num(get(handles.speed2Edit,'String'));
speed(3)=str2num(get(handles.speed3Edit,'String'));
speed(4)=str2num(get(handles.speed4Edit,'String'));
speed(5)=str2num(get(handles.speed5Edit,'String'));
speed(6)=str2num(get(handles.speed6Edit,'String'));
speed(7)=str2num(get(handles.speed7Edit,'String'));
speed(8)=str2num(get(handles.speed8Edit,'String'));
speed(9)=str2num(get(handles.speed9Edit,'String'));
speed(10)=str2num(get(handles.speed10Edit,'String'));
speed(11)=str2num(get(handles.speed11Edit,'String'));
speed(12)=str2num(get(handles.speed12Edit,'String'));
speed(13)=str2num(get(handles.speed13Edit,'String'));
speed(14)=str2num(get(handles.speed14Edit,'String'));
speed(15)=str2num(get(handles.speed15Edit,'String'));
turn(1)=str2num(get(handles.turn1Edit,'String'));
turn(2)=str2num(get(handles.turn2Edit,'String'));
turn(3)=str2num(get(handles.turn3Edit,'String'));
turn(4)=str2num(get(handles.turn4Edit,'String'));
turn(5)=str2num(get(handles.turn5Edit,'String'));
turn(6)=str2num(get(handles.turn6Edit,'String'));
turn(7)=str2num(get(handles.turn7Edit,'String'));
turn(8)=str2num(get(handles.turn8Edit,'String'));
turn(9)=str2num(get(handles.turn9Edit,'String'));
turn(10)=str2num(get(handles.turn10Edit,'String'));
turn(11)=str2num(get(handles.turn11Edit,'String'));
turn(12)=str2num(get(handles.turn12Edit,'String'));
turn(13)=str2num(get(handles.turn13Edit,'String'));
turn(14)=str2num(get(handles.turn14Edit,'String'));
turn(15)=str2num(get(handles.turn15Edit,'String'));
dir(1) = 128;
dir(2) = 128;
dir(3) = 128;
dir(4) = 128;
dir(5) = 128;
dir(6) = 128;
dir(7) = 128;
dir(8) = 128;
dir(9) = 128;
dir(10) = 128;
dir(11) = 128;
dir(12) = 128;
dir(13) = 128;
dir(14) = 128;
dir(15) = 128;
packetData = buildDiffDataPacket(speed,dir,turn);
routePackets(2,botPacket(packetData));
packetData

% --------------------------------------------------------------------
function varargout = speed60Button_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.speed60Button.
global TURN
global SPEED
global DIR
SPEED=60;
packetData = buildDataPacket(60,DIR,TURN);
routePackets(2,botPacket(packetData));
packetData

% --------------------------------------------------------------------
function varargout = speedEdit_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.speedEdit.
global TURN
global SPEED
global DIR
SPEED=str2num(get(handles.speedEdit,'String'));
packetData = buildDataPacket(SPEED,DIR,TURN);
routePackets(2,botPacket(packetData));
packetData

% --------------------------------------------------------------------
function varargout = turnEdit_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.turnEdit.
global TURN
global SPEED
global DIR
TURN=str2num(get(handles.turnEdit,'String'));
packetData = buildDataPacket(SPEED,DIR,TURN);
routePackets(2,botPacket(packetData));

