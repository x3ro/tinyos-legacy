function routeByLocationMessageReceived(address, message)
global MAG_TRACKING


destination = message.get_destinationAddress;
source = message.get_sourceAddress;
origin = message.get_originAddress;
MAG_TRACKING.packetTimes(find(MAG_TRACKING.decimalNodeIDs==source),find(MAG_TRACKING.decimalNodeIDs==destination)) = cputime;

if(origin==source)
    MAG_TRACKING.xPositionEstimates(end+1)=message.get_xEstimate/256;
    MAG_TRACKING.yPositionEstimates(end+1)=message.get_yEstimate/256;
    MAG_TRACKING.PositionEstimateTimes(end+1)=cputime;
end