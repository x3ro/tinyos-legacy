function routeByBroadcastMessageReceived(address, message)
%This function receives all routeByBroadcast messages.  These messages are
%sent to broadcast a new magnetometer reading, so I take the magnetometer
%reading and store it with a timestamp
global MAG_TRACKING

if message.get_tupleType==20 %only process the mag readings for now (don't worry about localization updates)
	nodeID = getLocation(message.get_originAddress)+1;
	MAG_TRACKING.magReadings(nodeID(1), nodeID(2))=message.get_mag;
	MAG_TRACKING.magTimes(nodeID(1), nodeID(2)) = cputime;
end