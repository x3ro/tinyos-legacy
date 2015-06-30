function magTrackingNetworkStatisticsMessageReceived(address, message)
%This function receives all messages and updates the network statistics
%that we are trying to keep on the magTracking demo
global MAG_NET_STATS

%HISTORY OF WHO IS SENDING MAG READINGS
if message.amType==101 & message.get_routingProtocol==98
	a =message.get_originAddress;
	if ~isempty(a)
        MAG_NET_STATS.magReadingSourceIDHistory(:,end+1)=[a; cputime];
%        MAG_NET_STATS.magReadingSourceIDTimes(end+1)=cputime;
    end
end

%HISTORY OF THE KINDS OF PACKETS WE ARE RECEIVING
a =message.amType;
if ~isempty(a)
	MAG_NET_STATS.packetTypeHistory(:,end+1)=[a;cputime];
%	MAG_NET_STATS.packetTypeTimes(end+1)=cputime;
%	MAG_NET_STATS.packetTypeHistory(2,end+1)=cputime;
end

%HISTORY OF THE TOTAL NETWORK TRAFFIC
MAG_NET_STATS.totalTrafficCount=MAG_NET_STATS.totalTrafficCount+1;
