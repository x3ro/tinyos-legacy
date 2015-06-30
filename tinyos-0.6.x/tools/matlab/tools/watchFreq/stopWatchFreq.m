function stopWatchFreq(varargin)
%stopWatchFreq(moteID)
%
%USAGE:     stopWatchFreq(moteID)
%
%This function takes the moteID of a mote and stops watch from watching it

if length(varargin)>0
    moteIDs = varargin{1};
else
    moteIDs = 'all';
end

packetPorts = getPortMapping(moteIDs);
removePacketListeners(packetPorts, 'watchFreqReceiveNewData');

%we should probably also remove these mote IDs from the watch Params
%watchParams.moteIDs = moteIDs;

