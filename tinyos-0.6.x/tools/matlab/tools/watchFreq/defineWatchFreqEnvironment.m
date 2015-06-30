%this function should be run before running the watchFreq functions

global ROOT
addpath([ROOT '/tools/watchFreq'])
addpath([ROOT '/shared/oscope']);
addpath([ROOT '/contrib/kamin/util']);
defineOscopeEnvironment

global DEFAULT_WATCH_NODES_PARAMS
DEFAULT_WATCH_NODES_PARAMS.fieldName='moteID';%'data';      %this is the name of the field that will be watched
DEFAULT_WATCH_NODES_PARAMS.addMethod='addDataToWatchFreq';      %this is the name of the function used to add new data
DEFAULT_WATCH_NODES_PARAMS.filterName='';      %this is the name of the function used to add new data
DEFAULT_WATCH_NODES_PARAMS.timeWindow=100;          %this is the number of data points stored by the watch
DEFAULT_WATCH_NODES_PARAMS.packetPort = [];       %this is the amount of space at the end
DEFAULT_WATCH_NODES_PARAMS.history = [];       %this is the amount of space at the end
DEFAULT_WATCH_NODES_PARAMS.sortBy = 1;       %indicates what to sort bar graph according to.  1=sort by Value, 2=sortbyFreq

global WATCH_NODES_PLOT_FUNCTION
WATCH_NODES_PLOT_FUNCTION = 'bar'; % you could change this to 'loglog' or whatever you want