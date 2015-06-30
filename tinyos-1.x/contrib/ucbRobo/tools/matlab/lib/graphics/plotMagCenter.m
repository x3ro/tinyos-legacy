function plotMagCenter(X, Y, intensity)
% Clean up this code later.
Ithresh = 0;%30;
persistent magCenters;
persistent lastReadingX;
persistent lastReadingY;
persistent lastReadingIntensity;

magCenters = [ magCenters [X ; Y]];

persistent magCircleHandle;
persistent gridDrawn;
diameter = intensity/100; % arbitrary scaling factor

% !!! Should replace with auto-loaded mote layout
if (gridDrawn == true)
else
    plotGrid(8,4); % mote grid size is 9x5
end

if (isempty(lastReadingX)) || ~((lastReadingX == X) && (lastReadingY == Y) &&...
                                abs(lastReadingIntensity - intensity) < Ithresh )
    if ishandle(magCircleHandle)
        set(magCircleHandle,'Position',[X-diameter/2,Y-diameter/2,diameter,diameter]);
    else
        magCircleHandle = rectangle('Position',[X-diameter/2,Y-diameter/2,diameter,diameter],...
            'Curvature',[1,1],...
            'FaceColor','b'); % rectangle here plots a circle
    end
    refresh;
    lastReadingIntensity = intensity; % only update if we replot
end

% % partition region, for easier reading
% line([-1 10],[4.5 4.5]);    
% line([4.5 4.5],[-1 10]);
lastReadingX = X;
lastReadingY = Y;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotGrid(Xdimension,Ydimension)
% plots motes as circles using rectangle
diameter = 0.25;

for i = 0:Xdimension
    for j = 0:Ydimension
        rectangle('Position',[i-diameter/2,j-diameter/2,diameter,diameter],...
            'Curvature',[1,1],...
            'FaceColor','r');
    end
end

daspect([1,1,1]);