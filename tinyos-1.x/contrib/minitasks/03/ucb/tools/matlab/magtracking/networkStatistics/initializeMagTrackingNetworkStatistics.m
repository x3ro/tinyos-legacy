function handle = initializeMagTrackingNetworkStatistics()
%initializeMagTrackingNetworkStatistics()
%
%This function will initialize the histogram part of mag tracking, which
%shows stats about the incoming packets
    
global MAG_NET_STATS

subplotRows=3;
subplotCols=1;

%create the figure that we'll be using
MAG_NET_STATS.fig = figure;
%set(MAG_TRACKING.fig, 'Position', [get(0, 'ScreenSize')]);
set(gcf,'DoubleBuffer', 'on');
set(gcf,'BackingStore', 'on');
set(gcf,'Renderer', 'OpenGL');

MAG_NET_STATS.nodeIDs = ['200'; '210'; '220'; '230'; '240';
                            '201'; '211'; '221'; '231'; '241';
                            '202'; '212'; '222'; '232'; '242';
                            '203'; '213'; '223'; '233'; '243';
                            '204'; '214'; '224'; '234'; '244'];
MAG_NET_STATS.nodePositions = ['(0,0)'; '(1,0)'; '(2,0)'; '(3,0)'; '(4,0)';
                            '(0,1)'; '(1,1)'; '(2,1)'; '(3,1)'; '(4,1)';
                            '(0,2)'; '(1,2)'; '(2,2)'; '(3,2)'; '(4,2)';
                            '(0,3)'; '(1,3)'; '(2,3)'; '(3,3)'; '(4,3)';
                            '(0,4)'; '(1,4)'; '(2,4)'; '(3,4)'; '(4,4)'];
MAG_NET_STATS.decimalNodeIDs= hex2dec(MAG_NET_STATS.nodeIDs);

%HISTORY OF WHO IS SENDING MAG READINGS
MAG_NET_STATS.magReadingSourceIDHistory=[0;0];
%MAG_NET_STATS.magReadingSourceIDTimes=[];
MAG_NET_STATS.magReadingSourceIDTimeout=1; %this is a time in seconds
MAG_NET_STATS.magReadingSourceIDSubplot=subplot(3,1,1);

%HISTORY OF THE KINDS OF PACKETS WE ARE RECEIVING
MAG_NET_STATS.packetTypeHistory=[0;0];
%MAG_NET_STATS.packetTypeTimes=[];
MAG_NET_STATS.packetTypeTimeout=1; %this is a time in seconds
MAG_NET_STATS.packetTypes.values = [100 101 102];
MAG_NET_STATS.packetTypes.names = {'Camera Control', 'Mag Readings', 'Pos Estimate'};
MAG_NET_STATS.packetTypeSubplot=subplot(3,1,2);

%HISTORY OF THE TOTAL NETWORK TRAFFIC
MAG_NET_STATS.totalTrafficCount=0;
MAG_NET_STATS.totalTrafficHistory=[];
MAG_NET_STATS.totalTrafficLength=30;
MAG_NET_STATS.totalTrafficTimes = [];
MAG_NET_STATS.totalTrafficSubplot=subplot(3,1,3);

%The timer that controls the network stats window.  This must be turned on
%and off manually because it brings the stats window to the front.
MAG_NET_STATS.timer = timer('TimerFcn','drawMagTrackingNetworkStatistics', 'Period', .3,'Name', 'Network Statistics','ExecutionMode','fixedRate');
start(MAG_NET_STATS.timer) %you can also use the "play" button on the gui to start the timer
