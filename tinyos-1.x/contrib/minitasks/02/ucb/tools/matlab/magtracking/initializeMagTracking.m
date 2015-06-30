function initializeMagTracking(varargin)
%initializeMagTracking()
%
%This function will initialize magTracking, which is an application
%that will track an evader.
    
global MAG_TRACKING

%first, define the gradient colormap that will be used to draw the magnetic
%field.  In this case, we use copper and cut off the lower end of the
%gradient so that it shows up well on a lcd projector
MAG_TRACKING.copp = copper;
MAG_TRACKING.copp = MAG_TRACKING.copp([1 22:end],:);

MAG_TRACKING.nodeIDs = ['200'; '210'; '220'; '230'; '240';
                            '201'; '211'; '221'; '231'; '241';
                            '202'; '212'; '222'; '232'; '242';
                            '203'; '213'; '223'; '233'; '243';
                            '204'; '214'; '224'; '234'; '244'];
MAG_TRACKING.decimalNodeIDs= hex2dec(MAG_TRACKING.nodeIDs);

MAG_TRACKING.fig=figure;
%set(MAG_TRACKING.fig, 'Position', [get(0, 'ScreenSize')]);
MAG_TRACKING.axes=axes;

%SET THE COLORS AND SIZE OF THE DOTS THAT INDICATE NODE LOCATIONS
MAG_TRACKING.networkPlot = plot(0,0,'.');
hold on
set(MAG_TRACKING.networkPlot,'MarkerSize',30)
set(MAG_TRACKING.networkPlot,'Color',[255 255 153]/255)%[153 204 255]/255)
set(MAG_TRACKING.networkPlot, 'XData', [], 'YData', []); %clear the plot

%PLOT THE DOTS INDICATING THE NODES OF THE NETWORK
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




%CREATE THE ARRAYS TO HOLD THE MAG READINGS AND TIMESTAMPS
%These are arrays that can be fed into the CONTOUR function
if ~isfield(MAG_TRACKING,'magReadings')
    MAG_TRACKING.magReadings=zeros(sqrt(length(MAG_TRACKING.nodeIDs))+2);
    MAG_TRACKING.magTimes=zeros(sqrt(length(MAG_TRACKING.nodeIDs))+2);
end
MAG_TRACKING.magReadingTimeout=.750; %this is a time in seconds after which a mag readings will dissappear

%create the plot to hold the actual magnetometer readings and set colors
MAG_TRACKING.magnetometerPlot = plot(0,0,'.');
set(MAG_TRACKING.magnetometerPlot, 'Color', [153 51 51]/255);
set(MAG_TRACKING.magnetometerPlot, 'XData', [], 'YData', []);
set(MAG_TRACKING.magnetometerPlot,'MarkerSize',30)

%create the plot to hold the magnetometer contour
[C, MAG_TRACKING.magContourPlot, cf] = contourf(zeros(sqrt(length(MAG_TRACKING.nodeIDs))));


%data and plot for tracking packets
if ~isfield(MAG_TRACKING,'packetTransmissions')
    MAG_TRACKING.packetTimes=zeros(length(MAG_TRACKING.nodeIDs));
end
MAG_TRACKING.packetTimeout=1.5; %this is a time in seconds after which the packet arrows will dissappear
MAG_TRACKING.routePlot = quiver([1],[1],[1],[1]);
delete(MAG_TRACKING.routePlot);
MAG_TRACKING.routePlot=[];




%NETWORK POSITION ESTIMATES
%these fields just hold the most recent position estimate
%notice that this is different from the camera position estimate in that
%the camera position estimates come only after being routed through the
%entire network
if ~isfield(MAG_TRACKING,'xPositionEstimates')
    MAG_TRACKING.xPositionEstimates=[];
    MAG_TRACKING.yPositionEstimates=[];
    MAG_TRACKING.PositionEstimateTimes=[];
end
MAG_TRACKING.PositionEstimateTimeout=1; %this is a time in seconds after which the current position estimate dissapears from the screen

%this determines the color and size of the plot showing the position estimate
MAG_TRACKING.evaderPlot = plot(0,0,'.');
set(MAG_TRACKING.evaderPlot, 'Color', [122 204 255]/255);%[204 51 0]/255);
set(MAG_TRACKING.evaderPlot, 'XData', [], 'YData', []);
set(MAG_TRACKING.evaderPlot,'MarkerSize',75)
set(MAG_TRACKING.evaderPlot,'LineWidth',3)






%CAMERA POSITION ESTIMATES
%data and plot for position estimates received by camera
%these fields just hold the most recent camera position estimate
if ~isfield(MAG_TRACKING,'CameraPositions')
    MAG_TRACKING.xCameraPositions=[];
    MAG_TRACKING.yCameraPositions=[];
    MAG_TRACKING.CameraPositionTimes=[];
end
MAG_TRACKING.CameraPositionTimeout=1;%this is a time in seconds after which the current position estimate dissapears from the screen

%this determines the color and size of the plot showing the camera position
%estimate.  Currently, it is a square
MAG_TRACKING.cameraPlot = plot(0,0,'s');
set(MAG_TRACKING.cameraPlot, 'Color', [122 204 255]/255);%[204 51 0]/255);
set(MAG_TRACKING.cameraPlot, 'XData', [], 'YData', []);
set(MAG_TRACKING.cameraPlot,'MarkerSize',75)
set(MAG_TRACKING.cameraPlot,'LineWidth',3)


%this is the timer object that will draw the display
MAG_TRACKING.timer = timer('TimerFcn','drawMagTracking', 'Period', .2,'Name', 'Mag Tracking Refresh','ExecutionMode','fixedRate');
start(MAG_TRACKING.timer) %you can also use the "play" button on the gui to start the timer
set(gcf,'DoubleBuffer', 'on');
set(gcf,'BackingStore', 'on');
set(gcf,'Renderer', 'OpenGL');
set(gcf,'Color',[0 0 0]); %make everything black
set(gca,'Color',[0 0 0]);
axis off
