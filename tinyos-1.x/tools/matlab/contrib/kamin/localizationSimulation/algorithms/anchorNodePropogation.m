function [t, numIterations] = anchorNodePropogation(t)
%t = anchorNodePropogation(t)
%
%this function uses leastSquaresMultilateration to find the positions of
%all nodes possible, given only the anchor nodes.  These new nodes also
%become anchor nodes and the process iterates until no new anchor nodes are
%created.

oldAnchorNodes = [];
numIterations=0;
tOriginal = t;
while length(t.anchorNodes) ~= length(oldAnchorNodes)
    t = leastSquaresMultilateration(t);
    oldAnchorNodes = t.anchorNodes;
    t.anchorNodes = t.nodeIDs(union(find(t.xyEstimate(:,1)), find(t.xyEstimate(:,2))));
    t.xy(t.xyEstimate>0) = t.xyEstimate(t.xyEstimate>0);
    numIterations=numIterations+1;
end
tOriginal.xyEstimate = t.xyEstimate;
t = tOriginal;
numIterations