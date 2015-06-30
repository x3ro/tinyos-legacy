function [x, y]=averagePosition(nodeIDs)
%[x y]=averagePosition(nodeIDs)
%
%this function returns [sum(xpositions)/length(nodeIDs), sum(ypositions)/length(nodeIDs)]

x=0;
y=0;
for i=1:length(nodeIDs)
    [X Y] = getLocation(nodeIDs(i));
    x = x + X;
    y = y + Y;
end
x = x/length(nodeIDs);
y = y/length(nodeIDs);