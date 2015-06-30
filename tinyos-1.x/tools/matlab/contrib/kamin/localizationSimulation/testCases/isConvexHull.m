function [boolean, outsider] = isConvexHull(xy, anchorPoints)
%boolean = isStable(connectivityMatrix)
%
%this function takes the connectivity matrix of a graph and indicates
%whether the graph is "stable". A graph is stable if every subset of nodes
%S in the graph is connected to S-bar with at least 3 non-colinear points
%
%connectivity is indicated by a positive value
n = size(connectivityMatrix,1);
for i=1:2^n-2
    bitmask = dec2bin(i);
    bitmask(end+1:n)='0';
    S = find(bitmask=='1');
    Sbar = find(bitmask=='0');
    if (sum(sum(connectivityMatrix(S,Sbar),1)>0,2)<3) & (sum(sum(connectivityMatrix(S,Sbar),2)>0,1)<3)
        boolean=0;
        return
    end
end
boolean=1;
