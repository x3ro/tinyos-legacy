function drawMagTracking
%this function will use the MAG_TRACKING data structure and display
%something on the screen representing the internal workings of the demo

global MAG_TRACKING

%don't draw anything if this is not the fig that the user is looking at
if get(0,'CurrentFigure')~=MAG_TRACKING.fig
    return
end

%PLOT OF MAGNETOMETER READINGS
%choose the mag data that has not timed out yet and add it to the
%magnetometer plot
[magx magy] = find(cputime - MAG_TRACKING.magTimes < MAG_TRACKING.magReadingTimeout);
set(MAG_TRACKING.magnetometerPlot, 'XData', magx-1, 'YData', magy-1);

%erase the old contour if it exists
if ~isempty(MAG_TRACKING.magContourPlot)
    delete(MAG_TRACKING.magContourPlot);
    MAG_TRACKING.magContourPlot=[];
end

%and create new contours using the current magx magy data if it exists
if ~isempty(magx) & ~isempty(magy)
	temp=zeros(sqrt(length(MAG_TRACKING.nodeIDs))+2); %temp is the data structure used to hold the new mag data
	temp(sub2ind(size(MAG_TRACKING.magReadings), magx+1, magy+1)) = MAG_TRACKING.magReadings(sub2ind(size(MAG_TRACKING.magReadings), magx, magy));%magx, magy);
	[C, MAG_TRACKING.magContourPlot, cf] = contourf([-1:.25:5], [-1:.25:5],interp2(temp',2),20); %create the contour plot
    for i=1:length(MAG_TRACKING.magContourPlot)
         set(MAG_TRACKING.magContourPlot(i), 'EdgeColor', 'none');  %make it look nice
    end
    colormap(MAG_TRACKING.copp)
end
%disp('plotted mags')







%PLOT OF MULTIHOP PACKETS
%delete the old arrows if they exist
if ~isempty(MAG_TRACKING.routePlot)
    delete(MAG_TRACKING.routePlot);
    MAG_TRACKING.routePlot=[];
end

%figure out which pairs of motes have had a packet transmission recently
[sources destinations] = find(cputime - MAG_TRACKING.packetTimes < MAG_TRACKING.packetTimeout);
sourceIDs = MAG_TRACKING.nodeIDs(sources,:);
destinationIDs = MAG_TRACKING.nodeIDs(destinations,:);
%and create new arrows using the QUIVER function
if ~isempty(sourceIDs) & ~isempty(destinationIDs)
    x = str2num(sourceIDs(:,2));
    y = str2num(sourceIDs(:,3));
	u = str2num(destinationIDs(:,2))-x;
	v = str2num(destinationIDs(:,3))-y;
%    subplot(MAG_TRACKING.axes);
	MAG_TRACKING.routePlot = quiver(x,y,u,v, 0);
    for i=1:length(MAG_TRACKING.routePlot)
        %set the size and color of the arrows here
         set(MAG_TRACKING.routePlot(i), 'LineWidth', 3);
         set(MAG_TRACKING.routePlot(i), 'Color', [133 184 50]/255);%[102 153 204]/255);%[153 153 51]/255);%[174 208 0]/255);
    end
end
%disp('plotted packets')







%NETWORK POSITION ESTIMATES
if cputime-MAG_TRACKING.PositionEstimateTimes< MAG_TRACKING.PositionEstimateTimeout
    set(MAG_TRACKING.evaderPlot, 'XData', MAG_TRACKING.xPositionEstimates, 'YData', MAG_TRACKING.yPositionEstimates);
end
%disp('plotted positionestimates')






%CAMERA POSITION ESTIMATES
if cputime-MAG_TRACKING.CameraPositionTimes< MAG_TRACKING.CameraPositionTimeout
    set(MAG_TRACKING.cameraPlot, 'XData', MAG_TRACKING.xCameraPositions, 'YData', MAG_TRACKING.yCameraPositions);
end
%disp('plotted camera estimates')
