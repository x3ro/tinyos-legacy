function oscope(varargin)
%This function is the interface to control the matlab oscilloscope application

%%%%%%%%%%%%%%%%%%
%% The following block is the standard matlab/TinyOS app.
%% Functions specific to this application are below
%%%%%%%%%%%%%%%%%

if nargin>0 & ischar(varargin{1})
  %% the user or timer is calling one of the functions below
  feval(varargin{1},varargin{2:end});
  
elseif nargin==0 
  usage;
end


function usage
fprintf('USAGE:\n\toscilloscope(''init'')\n\toscilloscope(''start'')\n\toscilloscpe(''reset'')\n\tetc.\n')


%%%%%%%%%%%%%%%%%%
%% StdControl:
%%   init
%%   reinit
%%   start
%%   restart
%%   stop
%%%%%%%%%%%%%%%%%
  
function init(varargin)
%% create a global structure to hold persistent state for this application
global OSCOPE

%% import all necessary java packages
import net.tinyos.*
import net.tinyos.message.*
import net.tinyos.oscope.*

%% connect to the network
connect('sf@localhost:9001');

%% instantiate the application message types for future use
OSCOPE.oscopeMsg = oscope.OscopeMsg;
OSCOPE.resetMsg = oscope.OscopeResetMsg;

%% instantiate a timer
OSCOPE.timer = timer('Name', 'Oscope Timer','TimerFcn',@timerFired,'ExecutionMode','fixedRate','Period',10);

function start
global OSCOPE
%% register as a listener to OscopeMsg objects
receive(@oscopeMessageReceived,OSCOPE.oscopeMsg);
%% start the timer
startTimer(OSCOPE.timer)

function stop
global OSCOPE
%% unregister as a listener to OscopeMsg objects
stopReceiving(@oscopeMessageReceived,OSCOPE.oscopeMsg);
%% stop the timer
stopTimer(OSCOPE.timer)


%%%%%%%%%%%%%%%%%%
%% Timer:
%%   timerFired
%%%%%%%%%%%%%%%%%

function timerFired
reset;


%%%%%%%%%%%%%%%%%%
%% Message Receive Events
%%%%%%%%%%%%%%%%%

function oscopeMessageReceived(address, oscopeMsg, varargin)
global OSCOPE
xdata = get(OSCOPE.plot,'XData');
ydata = get(OSCOPE.plot,'YData');
set(OSCOPE.plot,'XData',[xdata oscopeMsg.lastSampleNumber-9:oscopeMsg.lastSampleNumber]);
set(OSCOPE.plot,'YData',[ydata oscopeMsg.get_data']);



%%%%%%%%%%%%%%%%%%
%% User Defined Functions
%%%%%%%%%%%%%%%%%

function reset(address)
global OSCOPE
global COMM
%% reset all nodes, unless user specified somebody specific
if nargin<1 address = COMM.TOS_BCAST_ADDR; end
send(address,OSCOPE.resetMsg);
%% reset the plot
set(OSCOPE.plot,'XData',[]);
set(OSCOPE.plot,'YData',[]);
