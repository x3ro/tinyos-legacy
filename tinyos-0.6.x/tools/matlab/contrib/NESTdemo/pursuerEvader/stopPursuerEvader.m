function stopPursuerEvader(varargin)
%stopPursuerEvader()
%
%This function will remove listeners from the generic_base packetPort
%and get ready to start handling incoming sensor readings

global NETWORK_MOTE_IDS
global GENERIC_BASE

%removePacketListeners(getPortMapping(NETWORK_MOTE_IDS), 'pursuerEvaderReceivePackets');
removePacketListeners(getPortMapping(GENERIC_BASE), 'pursuerEvaderReceivePackets');