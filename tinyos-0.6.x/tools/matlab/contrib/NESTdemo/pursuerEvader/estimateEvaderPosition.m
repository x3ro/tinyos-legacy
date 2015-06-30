function [x, y]=estimateEvaderPosition(readings)
%[x y]=estimateEvaderPosition(readings)
%
%this function takes the node IDs and tof readings sent to it
%and estimates the position of the evader

%[x y]=averagePosition(readings(:,1));


x=0;
y=0;
nodeIDs = readings(:,1);
for i=1:length(nodeIDs)
    [X Y] = getLocation(nodeIDs(i));
    x = x + X * readings(i,2);
    y = y + Y * readings(i,2);
end
x = x/sum(readings(:,2));
y = y/sum(readings(:,2));
