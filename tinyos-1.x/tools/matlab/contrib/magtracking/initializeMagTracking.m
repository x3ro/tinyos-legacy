function initializeMagTracking(varargin)
%initializeMagTracking()
%
%This function will initialize magTracking, which is an application
%that will track an evader.
    
global MAG_TRACKING
MAG_TRACKING.copp = copper
MAG_TRACKING.copp = MAG_TRACKING.copp([1 22:end],:)
%data and plot for network nodes
% MAG_TRACKING.nodeIDs = {'200' '210' '220' '230' '240';
%                             '201' '211' '221' '231' '241';
%                             '202' '212' '222' '232' '242';
%                             '203' '213' '223' '233' '243';
%                             '204' '214' '224' '234' '244'};
MAG_TRACKING.nodeIDs = ['200'; '210'; '220'; '230'; '240';
                            '201'; '211'; '221'; '231'; '241';
                            '202'; '212'; '222'; '232'; '242';
                            '203'; '213'; '223'; '233'; '243';
                            '204'; '214'; '224'; '234'; '244'];
MAG_TRACKING.decimalNodeIDs= hex2dec(MAG_TRACKING.nodeIDs);

hold off
MAG_TRACKING.networkPlot = plot(0,0,'.');
hold on
set(MAG_TRACKING.networkPlot,'MarkerSize',30)
set(MAG_TRACKING.networkPlot,'Color',[255 255 153]/255)%[153 204 255]/255)
set(MAG_TRACKING.networkPlot, 'XData', [], 'YData', []);

xData = get(MAG_TRACKING.networkPlot,'XData');
yData = get(MAG_TRACKING.networkPlot, 'YData');
for i=0:4
    for j=0:4
        xData = [xData i];
        yData = [yData j];
    end
end
set(MAG_TRACKING.networkPlot, 'XData', xData, 'YData', yData);
axis([-1 (max(xData)+1) -1 (max(yData)+1)])




%data and plot for magnetometer readings
if ~isfield(MAG_TRACKING,'magReadings')
    MAG_TRACKING.magReadings=zeros(sqrt(length(MAG_TRACKING.nodeIDs))+2);
    MAG_TRACKING.magTimes=zeros(sqrt(length(MAG_TRACKING.nodeIDs))+2);
end
MAG_TRACKING.magReadingTimeout=.750; %this is a time in seconds

MAG_TRACKING.magnetometerPlot = plot(0,0,'.');
set(MAG_TRACKING.magnetometerPlot, 'Color', [153 51 51]/255);
set(MAG_TRACKING.magnetometerPlot, 'XData', [], 'YData', []);
set(MAG_TRACKING.magnetometerPlot,'MarkerSize',30)
[C, MAG_TRACKING.magContourPlot, cf] = contourf(zeros(sqrt(length(MAG_TRACKING.nodeIDs))));
%delete(MAG_TRACKING.magContourPlot);


%data and plot for tracking packets
if ~isfield(MAG_TRACKING,'packetTransmissions')
    MAG_TRACKING.packetTimes=zeros(length(MAG_TRACKING.nodeIDs));
end
MAG_TRACKING.packetTimeout=1.5; %this is a time in seconds
MAG_TRACKING.routePlot = quiver([1],[1],[1],[1],'b');
delete(MAG_TRACKING.routePlot);
MAG_TRACKING.routePlot=[];




%data and plot for network position estimates
if ~isfield(MAG_TRACKING,'xPositionEstimates')
    MAG_TRACKING.xPositionEstimates=[];
    MAG_TRACKING.yPositionEstimates=[];
    MAG_TRACKING.PositionEstimateTimes=[];
end
MAG_TRACKING.PositionEstimateTimeout=1;
MAG_TRACKING.evaderHistoryLength=10;

MAG_TRACKING.evaderHistoryPlot = plot(0,0,'.');
set(MAG_TRACKING.evaderHistoryPlot, 'Color', [.75 0 0]);
set(MAG_TRACKING.evaderHistoryPlot, 'XData', [], 'YData', []);
set(MAG_TRACKING.evaderHistoryPlot,'LineWidth',2.5)
MAG_TRACKING.evaderPlot = plot(0,0,'.');
set(MAG_TRACKING.evaderPlot, 'Color', [122 204 255]/255);%[204 51 0]/255);
set(MAG_TRACKING.evaderPlot, 'XData', [], 'YData', []);
set(MAG_TRACKING.evaderPlot,'MarkerSize',75)
set(MAG_TRACKING.evaderPlot,'LineWidth',3)



%data and plot for position estimates received by camera
if ~isfield(MAG_TRACKING,'CameraPositions')
    MAG_TRACKING.xCameraPositions=[];
    MAG_TRACKING.yCameraPositions=[];
    MAG_TRACKING.CameraPositionTimes=[];
end
MAG_TRACKING.CameraPositionTimeout=1;
MAG_TRACKING.cameraHistoryLength=4;

MAG_TRACKING.cameraHistoryPlot = plot(0,0,'.');
set(MAG_TRACKING.cameraHistoryPlot, 'Color', [.75 0 0]);
set(MAG_TRACKING.cameraHistoryPlot, 'XData', [], 'YData', []);
set(MAG_TRACKING.cameraHistoryPlot,'LineWidth',2.5)
MAG_TRACKING.cameraPlot = plot(0,0,'s');
set(MAG_TRACKING.cameraPlot, 'Color', [122 204 255]/255);%[204 51 0]/255);
set(MAG_TRACKING.cameraPlot, 'XData', [], 'YData', []);
set(MAG_TRACKING.cameraPlot,'MarkerSize',75)
set(MAG_TRACKING.cameraPlot,'LineWidth',3)


%this is the timer object that will draw the display
MAG_TRACKING.timer = timer('TimerFcn','drawMagTracking', 'Period', .2,'Name', 'Mag Tracking Refresh','ExecutionMode','fixedRate');
start(MAG_TRACKING.timer) %use the "play" button on the gui to start the timer
%set(h,'EraseMode','normal'); 
set(gcf,'DoubleBuffer', 'on');
set(gcf,'BackingStore', 'on');
set(gcf,'Renderer', 'OpenGL');
set(gcf,'Color',[0 0 0]);
set(gca,'Color',[0 0 0]);
axis off
