function drawMagTracking
%this function will use the MAG_TRACKING data structure and display
%something on the screen representing the internal workings of the demo

global MAG_TRACKING

%plot for magnetometer readings
[magx magy] = find(cputime - MAG_TRACKING.magTimes < MAG_TRACKING.magReadingTimeout);
set(MAG_TRACKING.magnetometerPlot, 'XData', magx-1, 'YData', magy-1);
if ~isempty(MAG_TRACKING.magContourPlot)
    delete(MAG_TRACKING.magContourPlot);
    MAG_TRACKING.magContourPlot=[];
end
if ~isempty(magx) & ~isempty(magy)
	temp=zeros(sqrt(length(MAG_TRACKING.nodeIDs))+2);
	temp(magx+1, magy+1) = MAG_TRACKING.magReadings(magx, magy);
	[C, MAG_TRACKING.magContourPlot, cf] = contourf([-1:.25:5], [-1:.25:5],interp2(temp',2),20);
    for i=1:length(MAG_TRACKING.magContourPlot)
         set(MAG_TRACKING.magContourPlot(i), 'EdgeColor', 'none');
%         set(MAG_TRACKING.magContourPlot(i), 'FaceColor', 'interp');
%          set(MAG_TRACKING.magContourPlot(i), 'MarkerEdgeColor', 'none');
    end
    colormap(MAG_TRACKING.copp)
end
%disp('plotted mags')

%plot for tracking packets
[sources destinations] = find(cputime - MAG_TRACKING.packetTimes < MAG_TRACKING.magReadingTimeout);
sourceIDs = MAG_TRACKING.nodeIDs(sources,:);
destinationIDs = MAG_TRACKING.nodeIDs(destinations,:);
if ~isempty(MAG_TRACKING.routePlot)
    delete(MAG_TRACKING.routePlot);
    MAG_TRACKING.routePlot=[];
end
if ~isempty(sourceIDs) & ~isempty(destinationIDs)
    x = str2num(sourceIDs(:,2));
    y = str2num(sourceIDs(:,3));
	u = str2num(destinationIDs(:,2))-x;
	v = str2num(destinationIDs(:,3))-y;
	MAG_TRACKING.routePlot = quiver(x,y,u,v, 0);
    for i=1:length(MAG_TRACKING.routePlot)
         set(MAG_TRACKING.routePlot(i), 'LineWidth', 3);
         set(MAG_TRACKING.routePlot(i), 'Color', [133 184 50]/255);%[102 153 204]/255);%[153 153 51]/255);%[174 208 0]/255);
%         set(MAG_TRACKING.magContourPlot(i), 'FaceColor', 'interp');
%          set(MAG_TRACKING.magContourPlot(i), 'MarkerEdgeColor', 'none');
    end
end
%disp('plotted packets')

%plot for network position estimates
MAG_TRACKING.xPositionEstimates = timeWindow(MAG_TRACKING.xPositionEstimates, MAG_TRACKING.evaderHistoryLength);
MAG_TRACKING.yPositionEstimates = timeWindow(MAG_TRACKING.yPositionEstimates, MAG_TRACKING.evaderHistoryLength);
MAG_TRACKING.PositionEstimateTimes = timeWindow(MAG_TRACKING.PositionEstimateTimes, MAG_TRACKING.evaderHistoryLength);
recent = find(cputime-MAG_TRACKING.PositionEstimateTimes< MAG_TRACKING.PositionEstimateTimeout);
%set(MAG_TRACKING.evaderHistoryPlot, 'XData', MAG_TRACKING.xPositionEstimates(recent), 'YData', MAG_TRACKING.yPositionEstimates(recent));
if ~isempty(recent)
    set(MAG_TRACKING.evaderPlot, 'XData', MAG_TRACKING.xPositionEstimates(recent(end)), 'YData', MAG_TRACKING.yPositionEstimates(recent(end)));
    %else
%    set(MAG_TRACKING.evaderPlot, 'XData', [], 'YData', []);
end
%disp('plotted positionestimates')

%plot for position estimates received by camera
MAG_TRACKING.xCameraPositions = timeWindow(MAG_TRACKING.xCameraPositions, MAG_TRACKING.cameraHistoryLength);
MAG_TRACKING.yCameraPositions = timeWindow(MAG_TRACKING.yCameraPositions, MAG_TRACKING.cameraHistoryLength);
MAG_TRACKING.CameraPositionTimes = timeWindow(MAG_TRACKING.CameraPositionTimes, MAG_TRACKING.cameraHistoryLength);
recent = find(cputime-MAG_TRACKING.CameraPositionTimes< MAG_TRACKING.CameraPositionTimeout);
%set(MAG_TRACKING.cameraHistoryPlot, 'XData', MAG_TRACKING.xCameraPositions(recent), 'YData', MAG_TRACKING.yCameraPositions(recent));
if ~isempty(recent)
    set(MAG_TRACKING.cameraPlot, 'XData', MAG_TRACKING.xCameraPositions(recent(end)), 'YData', MAG_TRACKING.yCameraPositions(recent(end)));
    %else
%    set(MAG_TRACKING.cameraPlot, 'XData', [], 'YData', []);
end
%disp('plotted camera estimates')
