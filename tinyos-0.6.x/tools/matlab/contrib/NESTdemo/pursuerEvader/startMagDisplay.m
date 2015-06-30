function startPursuerEvader(varargin)
%startPursuerEvader()
%
%This function registers the listener to the relevant ports,
%preparing the application to receive data

global NETWORK_MOTE_IDS
global GENERIC_BASE
global mag_data_array
global MAG_DISPLAY_PLOT


mag_data_array = [];

%start listening to the network
%addPacketListeners(getPortMapping(NETWORK_MOTE_IDS), 'pursuerEvaderReceivePackets');
addPacketListeners(getPortMapping(GENERIC_BASE), 'magPlotReceivePackets');

%and then tell the network to start agro-ing
%routePackets(GENERIC_BASE, AgCommand(1,1));
MAG_DISPLAY_PLOT = plot([0], 'b');
axis([0 600 0 150]);
set(MAG_DISPLAY_PLOT,'LineWidth',3)
