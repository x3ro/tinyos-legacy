function initializePursuerEvader(varargin)
%initializePursuerEvader()
%
%This function will initialize pusuerEvader, which is an application
%that will track both a pursuer and an evader.
%It will erase NOT erase any data, simply ensures that you won't get 'out of bounds' errors
    
global T0 TPLOT
global PURSUER_EVADER
global TOF_CALIBRATION
global NETWORK_MOTE_IDS
global MAX_NETWORK_DIMENSION

global trackingHistoryLength;%this is the number of positions of the pursuer/evader that we graph
trackingHistoryLength=10 ;
global measurementHistoryLength;%this is the number of history measurements to use for current estimate
measurementHistoryLength=1;
global timeDelay  %time delay in second of received packets 
timeDelay = 0;
global samplesPerRegression %number of past samples used for regression
samplesPerRegression = 1;
global METHOD % linear or cubic regression
METHOD = 'linear'; 

T0 = clock;  %get current time
TPLOT = T0;  % in case we want to plot no more that one plot per second
%load the TOF CALIBRATION from the TOF_CALIBRATION file
%load TOF_CALIBRATION TOF_CALIBRATION

%initialize the locations where we store measurements
if ~isfield(PURSUER_EVADER,'pursuerMeasurements')
    PURSUER_EVADER.pursuerMeasurements=[];
end
if ~isfield(PURSUER_EVADER,'evaderMeasurements')
    PURSUER_EVADER.evaderMeasurements=[];
end
if ~isfield(PURSUER_EVADER,'pursuerPositions')
    PURSUER_EVADER.pursuerPositions=[];
end
if ~isfield(PURSUER_EVADER,'evaderPositions')
    PURSUER_EVADER.evaderPositions=[];
end
if ~isfield(PURSUER_EVADER,'pursuerPredictedPositions')
    PURSUER_EVADER.pursuerPredictedPositions=[];
end
if ~isfield(PURSUER_EVADER,'evaderPredictedPositions')
    PURSUER_EVADER.evaderPredictedPositions=[];
end
if ~isfield(PURSUER_EVADER,'pursuerPositionsHistory')
    PURSUER_EVADER.pursuerPositionsHistory=[];
end
if ~isfield(PURSUER_EVADER,'evaderPositionsHistory')
    PURSUER_EVADER.evaderPositionsHistory=[];
end
%for i=1:max(NETWORK_MOTE_IDS)
%    PURSUER_EVADER.pursuerMeasurements{i}=[];
%    PURSUER_EVADER.evaderMeasurements{i}=[];
%end

PURSUER_EVADER.evaderTime =[];
PURSUER_EVADER.pursuerTime =[];
PURSUER_EVADER.pursuerMeasurements={};
PURSUER_EVADER.evaderMeasurements={};
%for i=1:max(NETWORK_MOTE_IDS)
%    PURSUER_EVADER.pursuerMeasurements{i}=[];
%    PURSUER_EVADER.evaderMeasurements{i}=[];
%end

%create the plots that are going to be used for the visualization
hold off
PURSUER_EVADER.networkPlot = plot(0,0,'.k');
set(PURSUER_EVADER.networkPlot,'MarkerSize',30)
hold on
set(PURSUER_EVADER.networkPlot, 'XData', [], 'YData', []);
PURSUER_EVADER.magnetometerPlot = plot(0,0,'.g');
set(PURSUER_EVADER.magnetometerPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.magnetometerPlot,'MarkerSize',30)
PURSUER_EVADER.tofPlot = plot(0,0,'.m');
set(PURSUER_EVADER.tofPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.tofPlot,'MarkerSize',30)
PURSUER_EVADER.pursuerPlot = plot(0,0,'sr');
set(PURSUER_EVADER.pursuerPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.pursuerPlot,'LineWidth',15)
PURSUER_EVADER.evaderPlot = plot(0,0,'dr');
set(PURSUER_EVADER.evaderPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.evaderPlot,'LineWidth',15)
PURSUER_EVADER.pursuerHistoryPlot = plot(0,0,':r');
set(PURSUER_EVADER.pursuerHistoryPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.pursuerHistoryPlot,'LineWidth',2.5)
PURSUER_EVADER.evaderHistoryPlot = plot(0,0,':r');
set(PURSUER_EVADER.evaderHistoryPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.pursuerHistoryPlot,'LineWidth',2.5)
PURSUER_EVADER.routePlot = plot(0,0,':k');
set(PURSUER_EVADER.routePlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.routePlot,'LineWidth',2.5)
PURSUER_EVADER.pursuerPredictionPlot = plot(0,0,'--r');
set(PURSUER_EVADER.pursuerPredictionPlot, 'XData', [], 'YData', []);
PURSUER_EVADER.evaderPredictionPlot = plot(0,0,'--r');
set(PURSUER_EVADER.evaderPredictionPlot, 'XData', [], 'YData', []);

%plot the network nodes on the network plot
xData = get(PURSUER_EVADER.networkPlot,'XData');
yData = get(PURSUER_EVADER.networkPlot, 'YData');
for i=1:length(NETWORK_MOTE_IDS)
    [x y]=getLocation(NETWORK_MOTE_IDS(i));
    xData = [xData x];
    yData = [yData y];
end
set(PURSUER_EVADER.networkPlot, 'XData', xData, 'YData', yData);
axis([-.5 (MAX_NETWORK_DIMENSION-.5) -.5 (MAX_NETWORK_DIMENSION-.5)])
    
