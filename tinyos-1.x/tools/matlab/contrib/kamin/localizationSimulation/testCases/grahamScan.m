function [convexHull, slope, dx] = grahamScan(xy)
%convexHull = grahamScan(xy)
%
%this function takes the xy coords of a graph and returns the points that
%would form a convex hull.
%
%This function also returns the slope of each edge of the convex hull
%(going counter-clockwise) and the change in x.

warning off MATLAB:divideByZero

[dummy,index] = min(xy(:,1));
convexHull=index;
dx = xy(:,1) - xy(index,1);
dy = xy(:,2) - xy(index, 2);

dx2 = dx(dx~=0);
dy2 = dy(dx~=0);
slope = dy2./dx2;

[dummy, newNodeOrder] = sort(slope);
finiteSlopeNodes = find(dx~=0);
newNodeOrder = finiteSlopeNodes(newNodeOrder);

infiniteSlopeNodes = find(dx==0);
dy3 = dy(dx==0);
[values, infOrder] = sort(-dy3);
infOrder = infiniteSlopeNodes(infOrder);
newNodeOrder = [infOrder; newNodeOrder];
xy = xy(newNodeOrder,:);

clear slope
x(1) = xy(2,1) - xy(1,1);
slope(1) = (xy(2,2) - xy(1,2))/x(1);
i=2;
while i <=size(xy,1)-1
    if ~any(convexHull==newNodeOrder(i)) convexHull(end+1)=newNodeOrder(i); end
    x(end+1)=xy(i+1,1) - xy(i,1);
    slope(end+1) = (xy(i+1,2) - xy(i,2))/x(end);
    if (slope(end) > slope(end-1) & x(end)*x(end-1) >=0) | (slope(end) < slope(end-1) & x(end)*x(end-1) <=0) 
        i=i+1;
    else
        convexHull(end)=[];
        x(end-1:end)=[];
        slope(end-1:end)=[];
        xy = xy([1:i-1 i+1:end],:);
        newNodeOrder(i)=[];
        i=find(newNodeOrder==convexHull(end));
    end
end
x(end+1)=xy(1,1) - xy(i,1);
slope(end+1) = (xy(1,2) - xy(i,2))/x(end);
if (slope(end) > slope(end-1) & x(end)*x(end-1) >=0) | (slope(end) < slope(end-1) & x(end)*x(end-1) <=0) 
    convexHull(end+1)=newNodeOrder(i);
end
