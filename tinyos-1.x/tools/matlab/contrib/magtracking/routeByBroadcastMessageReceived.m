function routeByBroadcastMessageReceived(address, message)
global MAG_TRACKING


nodeID = getLocation(message.get_originAddress)+1;
if length(nodeID)<2
    disp('GOT A BAD PACKET')
    message
else
	MAG_TRACKING.magReadings(nodeID(1), nodeID(2))=message.get_mag;
	MAG_TRACKING.magTimes(nodeID(1), nodeID(2)) = cputime;
	%MAG_TRACKING.magTimes = timeWindow(MAG_TRACKING.magTimes, MAG_TRACKING.evaderHistoryLength);
end