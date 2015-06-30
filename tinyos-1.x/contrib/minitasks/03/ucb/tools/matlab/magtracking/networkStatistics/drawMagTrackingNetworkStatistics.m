function drawMagTrackingNetworkStatistics
%this function will use the MAG_NET_STATS data structure and display
%network statistics about the mag tracking demo

global MAG_NET_STATS

%don't draw anything if this is not the fig that the user is looking at
if get(0,'CurrentFigure')~=MAG_NET_STATS.fig
    return
end

currentTime=cputime;
%BRING THE FIGURE TO THE FOREFRONT

%HISTORY OF WHO IS SENDING MAG READINGS
%MAG_NET_STATS.magReadingSourceIDHistory=timeWindow(MAG_NET_STATS.magReadingSourceIDHistory, MAG_NET_STATS.magReadingSourceIDHistoryLength);
if ~isempty(MAG_NET_STATS.magReadingSourceIDHistory)
    recent=find(currentTime-MAG_NET_STATS.magReadingSourceIDHistory(2,:) < MAG_NET_STATS.magReadingSourceIDTimeout);
    MAG_NET_STATS.magReadingSourceIDHistory=MAG_NET_STATS.magReadingSourceIDHistory(:,recent);
end
subplot(MAG_NET_STATS.magReadingSourceIDSubplot)
a=axis;
freq(MAG_NET_STATS.magReadingSourceIDHistory(1,:),MAG_NET_STATS.decimalNodeIDs,MAG_NET_STATS.nodePositions);
%freq(MAG_NET_STATS.magReadingSourceIDHistory);
title(['Histogram of node IDs for last mag broadcasts'])
%xlabel('Node ID')
ylabel('# broadcasts')
axis tight
a2=axis;
a2(4)=min(30,max(a(4),a2(4)));
axis(a2);

%HISTORY OF THE KINDS OF PACKETS WE ARE RECEIVING
%MAG_NET_STATS.packetTypeHistory=timeWindow(MAG_NET_STATS.packetTypeHistory, MAG_NET_STATS.packetTypeHistoryLength);
if ~isempty(MAG_NET_STATS.packetTypeHistory)
    recent=find(currentTime-MAG_NET_STATS.packetTypeHistory(2,:) < MAG_NET_STATS.packetTypeTimeout);
    MAG_NET_STATS.packetTypeHistory=MAG_NET_STATS.packetTypeHistory(:,recent);
end
subplot(MAG_NET_STATS.packetTypeSubplot)
a=axis;
freq(MAG_NET_STATS.packetTypeHistory(1,:), MAG_NET_STATS.packetTypes.values, MAG_NET_STATS.packetTypes.names); %make sure we are only looking at these three packet type
title(['Histogram of last packet types received'])
%xlabel('Packet type')
ylabel('# packets received')
a2=axis;
a2(4)=min(30,max(a(4),a2(4)));
axis(a2);



%HISTORY OF THE TOTAL NETWORK TRAFFIC
MAG_NET_STATS.totalTrafficTimes(end+1)=currentTime;
if length(MAG_NET_STATS.totalTrafficTimes)>1
    MAG_NET_STATS.totalTrafficHistory(end+1) = MAG_NET_STATS.totalTrafficCount/(MAG_NET_STATS.totalTrafficTimes(end)-MAG_NET_STATS.totalTrafficTimes(end-1));
    MAG_NET_STATS.totalTrafficCount=0;
    MAG_NET_STATS.totalTrafficHistory = timeWindow(MAG_NET_STATS.totalTrafficHistory, MAG_NET_STATS.totalTrafficLength);
    MAG_NET_STATS.totalTrafficTimes = timeWindow(MAG_NET_STATS.totalTrafficTimes, MAG_NET_STATS.totalTrafficLength);
    subplot(MAG_NET_STATS.totalTrafficSubplot)
    a=axis;
    plot(MAG_NET_STATS.totalTrafficHistory);
    set(gca, 'xTickLabel',round(mod(MAG_NET_STATS.totalTrafficTimes,10)*10)/10)
    title(['Packet Rate'])
 %   xlabel('Time (sec)')
    ylabel('# packets per second')
	a2=axis;
    a2(4)=min(40,max(a(4),a2(4)));
	axis(a2);
end