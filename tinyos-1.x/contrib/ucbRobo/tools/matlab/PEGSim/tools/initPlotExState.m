function initPlotExState
  
global plotExState

plotExState.SNfignum = 1;
%plotExState.nodes can be uninitialized
plotExState.border = 5;
plotExState.senseR = [];
plotExState.commR = [];
plotExState.rTree = [];
plotExState.route = [];

%plotExState.P, plotExState.E can be uninitialized
plotExState.Ppath = [];
plotExState.Epath = [];

