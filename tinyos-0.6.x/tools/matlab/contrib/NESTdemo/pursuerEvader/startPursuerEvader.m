function startPursuerEvader(varargin)
%startPursuerEvader()
%
%This function registers the listener to the relevant ports,
%preparing the application to receive data

global NETWORK_MOTE_IDS
global GENERIC_BASE

%start listening to the network
%addPacketListeners(getPortMapping(NETWORK_MOTE_IDS), 'pursuerEvaderReceivePackets');
addPacketListeners(getPortMapping(GENERIC_BASE), 'pursuerEvaderReceivePackets');

%and then tell the network to start agro-ing
routePackets(GENERIC_BASE, AgCommand(1,1));
