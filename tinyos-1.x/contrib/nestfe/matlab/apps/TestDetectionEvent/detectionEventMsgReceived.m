function detectionEventMsgReceived(address, detectMsg, varargin)
% Parses detectMsg and then calls handlers
%
% NOTE: you may get some error messages like:
% "receive error for net.tinyos.drain_msgs.DetectionEvent.DetectionEventMsg
% (AM type 4): invalid length message received (too short)"
% these error messages are due to a hack to get embedded message parsing to
% work in matlab, and should not pose any serious problems.  You can ignore
% them.

global TESTDETECT

if (detectMsg.get_type ~= TESTDETECT.detectEventType)
    % ignores other types of drain messages
    return;
end

moteID = detectMsg.get_source;
detectTime = detectMsg.get___nesc_keyword_event_time;
xPos = detectMsg.get___nesc_keyword_event_location_x;
yPos = detectMsg.get___nesc_keyword_event_location_y;
strength = detectMsg.get___nesc_keyword_event_strength;
detectType = detectMsg.get___nesc_keyword_event_type;

if ~(TESTDETECT.ignoreNoTimeSyncFlag && detectTime == 0)
    if (TESTDETECT.printFlag)       disp(detectMsg); end
    if (TESTDETECT.graphFlag)       graphDetection(moteID,detectTime,xPos,yPos,strength,detectType); end
    if (TESTDETECT.drawFlag)        drawDetection(moteID,detectTime,xPos,yPos,strength,detectType); end
end
% Will log even if no timesync
if (TESTDETECT.logFlag)         logDetection(moteID,detectTime,xPos,yPos,strength,detectType); end


%%%%% Event Handlers %%%%%

%%% Helper function for graphDetection
    function moteLegend = genLegend(motes)
    for i = 1:length(motes)
        moteLegend{i} = sprintf('Mote %d',motes(i));
    end

% Plots a graph of the detections like an oscilloscope
function graphDetection(moteID,detectTime,xPos,yPos,strength,detectType)
global TESTDETECT
colors = ['b' 'g' 'r' 'c' 'm' 'y' 'k'];

% get/set the current figure
if ishandle(TESTDETECT.graphFigure)
    figure(TESTDETECT.graphFigure);
else
    scrsz = get(0,'ScreenSize');
    TESTDETECT.graphFigure = figure('Position',...
        [scrsz(3)/2 (scrsz(4)/2 - 50) (scrsz(3)/2 - 25) scrsz(4)/2],'DoubleBuffer','on');
end
hold on;

% get/set the proper line element for moteID
ind = find(TESTDETECT.motes == moteID);
if isempty(ind)
    TESTDETECT.motes(end+1) = moteID;
    ind = length(TESTDETECT.motes);
end;
if ~((length(TESTDETECT.graphPlot) >= ind) && ... 
     ishandle(TESTDETECT.graphPlot(ind)))
    mycolor = colors(mod(ind - 1,length(colors)) + 1);
    TESTDETECT.graphPlot(ind) = plot([0],mycolor);
    set(TESTDETECT.graphPlot(ind),'XData', []);
    set(TESTDETECT.graphPlot(ind),'YData', []);
    moteLegend = genLegend(TESTDETECT.motes);
    legend(TESTDETECT.graphPlot,moteLegend);
end

xdata = get(TESTDETECT.graphPlot(ind),'XData');
ydata = get(TESTDETECT.graphPlot(ind),'YData');

set(TESTDETECT.graphPlot(ind),'XData',[xdata detectTime]);
set(TESTDETECT.graphPlot(ind),'YData',[ydata strength]);

hold off;

%%% Helper function for drawDetection
    function fixAxes(xPos,yPos,mySize)
    global TESTDETECT
    myAx = get(TESTDETECT.drawFigure,'Children');
    myAxXlim = get(myAx,'XLim');
    myAxYlim = get(myAx,'YLim');
    if ((xPos-mySize/2) < myAxXlim(1) || ...
            (yPos-mySize/2) < myAxYlim(2) || ...
            (xPos+mySize/2) > myAxXlim(1) || ...
            (yPos+mySize/2) > myAxYlim(2))
        newXlim = [min(xPos-mySize/2,myAxXlim(1))
            max(xPos+mySize/2,myAxXlim(2))];
        newYlim = [min(yPos-mySize/2,myAxYlim(1))
            max(yPos+mySize/2,myAxYlim(2))];
        set(myAx,'Xlim',newXlim);
        set(myAx,'Ylim',newYlim);
    end
    

% Plots the position of the nodes that are detecting
% Color represents detectType
% Size of circle represents strength of detection
% LineWidth of edge reprsents how recently updated
function drawDetection(moteID,detectTime,xPos,yPos,strength,detectType)
global TESTDETECT

%hack to use configuration file
moteInd = find(TESTDETECT.sw.id == moteID);
if ~isempty(moteInd)
    moteInd;
    tempPos = TESTDETECT.sw.pos(moteInd,:);
    xPos = tempPos(1);
    yPos = tempPos(2);
end

%% Assumes strength in range from 0 to 65535
maxSize = 3;
mySize = 1;
colors = ['b' 'g' 'r' 'c' 'm' 'y']; % can't see text on black 'k'

% get/set the current figure
if ishandle(TESTDETECT.drawFigure)
    figure(TESTDETECT.drawFigure);
else
    scrsz = get(0,'ScreenSize');
    TESTDETECT.drawFigure = figure('Position',...
        [1 (scrsz(4)/2 - 50) (scrsz(3)/2 - 25) scrsz(4)/2],'DoubleBuffer','on');
end
%clf;
%axes('XLim',[-5 70],'YLim',[0 90],'Box','on');
hold on;
% get/set the proper line element for moteID
ind = find(TESTDETECT.motes == moteID);
if isempty(ind)
    TESTDETECT.motes(end+1) = moteID;
    ind = length(TESTDETECT.motes);
end;
if ~((length(TESTDETECT.drawPlot) >= ind) && ... 
     ishandle(TESTDETECT.drawPlot(ind)) && ...
     ishandle(TESTDETECT.drawLabelPlot(ind)))
    % ignores initial strength and type
    TESTDETECT.drawPlot(ind) = rectangle('Curvature',[1 1],...
        'Position',[xPos,yPos,mySize,mySize],'FaceColor',[0.5 0.5 0.5],...
        'LineWidth',3);
    TESTDETECT.drawLabelPlot(ind) = ...
        text(xPos+mySize/2,yPos+mySize/2,int2str(moteID));
else
%    mySize = maxSize * (strength*1000 + 1)/65535; % avoid size 0
    mySize = maxSize * (strength*10 + 1)/65535; % avoid size 0
    myPos = [xPos-mySize/2,yPos-mySize/2,mySize,mySize];
    myColor = colors(mod(detectType - 1,length(colors)) + 1);
    set(TESTDETECT.drawPlot(ind),'Position',myPos,'FaceColor',myColor,...
                                 'LineWidth',3);
    myLabelPos = [xPos,yPos,0];
    set(TESTDETECT.drawLabelPlot(ind),'Position',myLabelPos);
    
    % fix the axis if plotting out of range
    %fixAxes(xPos,yPos,mySize);
end
hold off;



function logDetection(moteID,detectTime,xPos,yPos,strength,detectType)
global MTT
if ~isfield(MTT,'reportMat') 
    MTT.reportMat = [];
end

timestamp = clock';
timestamp = timestamp(4:6);
% row 11 is reserved for MTT simulation use time.
data = [moteID ; 0 ; xPos ; yPos ; strength ; 0 ; detectTime; timestamp; 0];
MTT.reportMat = [MTT.reportMat data];
