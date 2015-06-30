function TestDetectionEvent(varargin)
%This function is the interface to control the TestDetectionEvent
%application

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
fprintf('USAGE:\n\tTestDetectionEvent''myinit'')\n\tTestDetectionEvent(''mystart'')\n\tTestDetectionEvent(''mystop'')\n\tTestDetectionEvent(''replayLog'', replayMat)\n\tetc.\n')


function myinit(noComm,varargin)
%% create a global structure to hold persistent state for this application
%% noComm is useful for playing the log without needing a serial forwarder
%% to be started
global TESTDETECT
global COMM

if (nargin >= 1) && strcmpi(noComm,'noComm')
    noCommFlag = true;
else
    noCommFlag = false;
end

%if sscanf(version('-release'),'%f') < 14
%   disp('Remember to set your classpath.txt to include the nestfe/java directory')
%else
    %UNTESTED.  What if init is called multiple times?
%    nestfe_classpath = 'c:/PROGRA~1/ucb/cygwin/opt/tinyos-1.x/contrib/nestfe/java';
%    javaclasspath(nestfe_classpath); %might not work... depends on installation
%    fprintf('Set java classpath to %s',nestfe_classpath);
%end

%% import all necessary java packages
import net.tinyos.*
import net.tinyos.message.*
import net.tinyos.drain_msgs.DetectionEvent.*
% use the TOS default group, not Kamin's DD group
%COMM.GROUP_ID = hex2dec('7d');
COMM.GROUP_ID = hex2dec('0a');
%COMM.GROUP_ID = hex2dec('33');
%COMM.GROUP_ID = 35;
fprintf('GroupID is set as %d',COMM.GROUP_ID);
%% connect to the network
if ~noCommFlag
    connect('sf@localhost:9001');
end

%% instantiate the application message types for future use
TESTDETECT.detectMsg = DetectionEventMsg;
TESTDETECT.detectEventType = DetectionEventConst.AM_DETECTIONEVENTMSG;
TESTDETECT.motes = [];
TESTDETECT.graphFigure = NaN; % make sure not a figure handle
TESTDETECT.drawFigure = NaN; % make sure not a figure handle
TESTDETECT.graphPlot = [];
TESTDETECT.drawPlot = [];
TESTDETECT.drawLabelPlot = [];

TESTDETECT.decayPeriod = 3;
TESTDETECT.clearPeriod = 300;

%% Not necessary for now
%TESTDETECT.motePos = [];
%TESTDETECT.motePosFile = '410Soda_test.cfg';
%loadMotePos(TESTDETECT.motePosFile)

TESTDETECT.printFlag = false;
TESTDETECT.drawFlag = true;
TESTDETECT.graphFlag = false;
TESTDETECT.logFlag = true;
TESTDETECT.cleanLogFlag = false;
TESTDETECT.ignoreNoTimeSyncFlag = false; % Does not affect logging
% Time = 0 is interpreted as no timesync (this is the convention in the
% nesC code)

%% instantiate a timer
TESTDETECT.decayTimer = timer('Name','Decay Timer', ...
                              'TimerFcn','decayTimerFired',...
                              'ExecutionMode','fixedRate','Period',TESTDETECT.decayPeriod);

% Hope this will allow matlab to run for long periods of time
TESTDETECT.clearTimer = timer('Name','Clear Data Timer', ...
                              'TimerFcn','clearTimerFired',...
                              'ExecutionMode','fixedRate','Period',TESTDETECT.clearPeriod);
%hack of locations
                          TESTDETECT.sw = read_swcfgfile('RFSmain.cfg');
                          
                          
function mystart
%% register as a listener to OscopeMsg objects
global TESTDETECT

if isempty(TESTDETECT)
    error('Make sure to call TestDetection myinit first');
end

receive('detectionEventMsgReceived',TESTDETECT.detectMsg);
%% start the timer
start(TESTDETECT.decayTimer)
start(TESTDETECT.clearTimer)



function mystop
%% unregister as a listener to OscopeMsg objects
global TESTDETECT

if isempty(TESTDETECT)
    error('Make sure to call TestDetection myinit first');
end

stopReceiving('detectionEventMsgReceived',TESTDETECT.detectMsg);
%% stop the timer
stop(TESTDETECT.decayTimer)
stop(TESTDETECT.clearTimer)



function replayLog(reportMat)
% replayLog(reportMat)
%
% Using the timestamps in the received detection messages, replay the
% log of detections by calling detectionEventMsgReceived repeatedly.
% Note that this may not be in the order which we received the messages.
% Assume timestamp in reportMat(7,:) in units of 1/65535 seconds.
%
% See replayTimerFired for implementation.
%
% NOTES:
% * Must run 'TestDetectionEvent myinit' before executing this function.
% * Cannot call by 'TestDetectionEvent replayLog reportMat', must call 
%   by 'TestDetectionEvent('replayLog', reportMat)'

global TESTDETECT;
global replayMat;
global replayIndex;
global replayTimer;
global replayTimerToggle;
global replayTime;

replayIndex = 1;
replayTime = 0;
replayMat = reportMat;
if isempty(replayMat)
    error('report matrix to be replayed is empty');
end

if (TESTDETECT.ignoreNoTimeSyncFlag)
    replayMat = replayMat(:,replayMat(7,:) ~= 0);
else
    %make best effort to insert non-timesynced messages
    nonZero = find(replayMat(7,:) ~= 0);
    if (replayMat(7,1) == 0)
        nonZero = [1 nonZero]; %add index 1, to allow interpolation from 1st reading
        %set artificial first time
        replayMat(7,1) = replayMat(7,nonZero(2)) - 0.001*nonZero(2);
    end
    if (replayMat(7,end) == 0)
        lastInd = size(replayMat,2);
        nonZero = [nonZero lastInd]; %add index 1, to allow interpolation from 1st reading
        %set artificial last time
        replayMat(7,lastInd) = replayMat(7,nonZero(end-1)) + 0.001*(lastInd - nonZero(end-1));
    end

    for i = 1:length(nonZero)-1
        lowerInd = nonZero(i);
        upperInd = nonZero(i+1);
        step = (replayMat(7,upperInd) - replayMat(7,lowerInd))/(upperInd - lowerInd);
        timeArr = replayMat(7,lowerInd):step:replayMat(7,upperInd);
        % not sure if calculation of timeArr is robust to roundoff errors
        replayMat(7,lowerInd:upperInd) = timeArr;
    end
end

% comment out the next line if you wish to see the reports in the order that
% they were received at the base station
replayMat = sortrows(replayMat',7)'; % order by time

replayTimerToggle = 1;
%% instantiate a timer, start as soon as possible
replayTimer{1} = timer('Name','Replay Log Timer', ...
                    'TimerFcn','replayTimerFired',...
                    'ExecutionMode','singleShot','Period',0.01);
replayTimer{2} = timer('Name','Replay Log Timer', ...
                    'TimerFcn','replayTimerFired',...
                    'ExecutionMode','singleShot','Period',0.01);
start(replayTimer{1});
