function resetPursuerEvader(varargin)
%resetPursuerEvader(varargin)
%
%This function erases all state.
%
global PURSUER_EVADER
global NETWORK_MOTE_IDS
global MAX_NETWORK_DIMENSION


%initialize the locations where we store measurements
if ~isfield(PURSUER_EVADER,'pursuerMeasurements')
    PURSUER_EVADER.pursuerMeasurements={}
end
if ~isfield(PURSUER_EVADER,'evaderMeasurements')
    PURSUER_EVADER.evaderMeasurements={}
end
for i=1:max(NETWORK_MOTE_IDS)
    PURSUER_EVADER.pursuerMeasurements{i}=[];
    PURSUER_EVADER.evaderMeasurements{i}=[];
end

PURSUER_EVADER.pursuerPositions=[];
PURSUER_EVADER.evaderPositions=[];

%reset all the plots
hold off
PURSUER_EVADER.networkPlot = plot(0,0,'.b');
hold on
set(PURSUER_EVADER.networkPlot, 'XData', [], 'YData', []);
PURSUER_EVADER.magnetometerPlot = plot(0,0,'.c');
set(PURSUER_EVADER.magnetometerPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.magnetometerPlot,'MarkerSize',30)
PURSUER_EVADER.tofPlot = plot(0,0,'.m');
set(PURSUER_EVADER.tofPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.tofPlot,'MarkerSize',30)
PURSUER_EVADER.pursuerPlot = plot(0,0,'or');
set(PURSUER_EVADER.pursuerPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.pursuerPlot,'LineWidth',15)
PURSUER_EVADER.evaderPlot = plot(0,0,'og');
set(PURSUER_EVADER.evaderPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.evaderPlot,'LineWidth',15)
PURSUER_EVADER.pursuerHistoryPlot = plot(0,0,':r');
set(PURSUER_EVADER.pursuerHistoryPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.pursuerHistoryPlot,'LineWidth',2.5)
PURSUER_EVADER.evaderHistoryPlot = plot(0,0,':g');
set(PURSUER_EVADER.evaderHistoryPlot, 'XData', [], 'YData', []);
set(PURSUER_EVADER.pursuerHistoryPlot,'LineWidth',2.5)
PURSUER_EVADER.pursuerPredictionPlot = plot(0,0,'--r');
set(PURSUER_EVADER.pursuerPredictionPlot, 'XData', [], 'YData', []);
PURSUER_EVADER.evaderPredictionPlot = plot(0,0,'--g');
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
