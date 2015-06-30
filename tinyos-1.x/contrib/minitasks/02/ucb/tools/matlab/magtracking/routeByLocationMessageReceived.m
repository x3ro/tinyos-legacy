function routeByLocationMessageReceived(address, message)
%This function receives all route by location packets.  Since these are
%only sent by the "leader" to indicate that the car is estimated to be at a
%certain position, I read off the position estimate and store it with a time 
%stamp.  I only do this if this is the first time the packet is being routed.
%I also read sender and receiver of this packet and store them no matter
%what.

global MAG_TRACKING


destination = message.get_destinationAddress;
source = message.get_sourceAddress;
origin = message.get_originAddress;
MAG_TRACKING.packetTimes(find(MAG_TRACKING.decimalNodeIDs==source),find(MAG_TRACKING.decimalNodeIDs==destination)) = cputime;

if(origin==source)
    MAG_TRACKING.xPositionEstimates=message.get_xEstimate/256;
    MAG_TRACKING.yPositionEstimates=message.get_yEstimate/256;
    MAG_TRACKING.PositionEstimateTimes=cputime;
end