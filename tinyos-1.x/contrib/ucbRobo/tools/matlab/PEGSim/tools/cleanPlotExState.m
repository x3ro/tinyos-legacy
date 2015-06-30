function cleanPlotExState
% Removes all plot state that are stale handles
global plotExState;

%plotExState.SNfignum
plotExState.nodes = plotExState.nodes(ishandle(plotExState.nodes));
%plotExState.border
plotExState.senseR = plotExState.senseR(ishandle(plotExState.senseR));
plotExState.commR = plotExState.commR(ishandle(plotExState.commR));
plotExState.rTree = plotExState.rTree(ishandle(plotExState.rTree));
%plotExState.route = plotExState.rTree(ishandle(plotExState.rTree));
