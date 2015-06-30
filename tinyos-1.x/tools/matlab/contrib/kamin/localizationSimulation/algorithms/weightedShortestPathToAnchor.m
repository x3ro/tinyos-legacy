function t = weightedShortestPathToAnchor(t)
%t = weightedShortestPathToAnchor(t)
%
%This function finds the shortest path from each node to all of the anchor
%nodes.  then, it gives the node the position with the lease error given
%those distances (using least squares).  This algorithm weights the effect
%of each anchor node based on the number of hops of shortest path found.

shortestPaths = -ones(size(t.kd));
pathLengths = zeros(size(t.kd));

%the following code finds the shortest paths from each node to every anchor
for i=t.anchorNodes
    anchor = (t.nodeIDs==i);
    [dummy, newNodeOrder] = sort(-anchor);
    tempkd = t.kd(newNodeOrder, newNodeOrder);
    tempkd(tempkd==-1) = zeros(1,sum(sum(logical(tempkd==-1))));
    sp = dijkstra(tempkd);
    shortestPaths(anchor, newNodeOrder(2:end)) = sp(:,2)';    
    shortestPaths(newNodeOrder(2:end), anchor) = sp(:,2);
    pathLengths(anchor, newNodeOrder(2:end)) = sp(:,4)';    
    pathLengths(newNodeOrder(2:end), anchor) = sp(:,4);
end

%calculate a correction factor
anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);
xy = t.xy(anchorIndices,1)+t.xy(anchorIndices,2)*1i;
[X,Y] = meshgrid(xy);
anchorDists = abs(X-Y);
measuredDists = shortestPaths(anchorIndices, anchorIndices);
scalingFactor = mean(median(anchorDists./measuredDists));
%scalingFactor = sum(anchorDists,2)./sum(measuredDists,2);


%the following code finds the best 3 anchors for each node
mobileNodes = find(vectorFind(setdiff(t.nodeIDs, t.anchorNodes), t.nodeIDs));
tempT = t;
%shortestPaths(mobileNodes, anchorIndices) = shortestPaths(mobileNodes, anchorIndices).*scalingFactor(:,ones(1,length(mobileNodes)))';
tempT.kd = shortestPaths*scalingFactor;
for i=mobileNodes'
    totalAnchors = sum(pathLengths(i,:)>0);
    pathlength = 1;
    tempT.anchorNodes = t.nodeIDs((pathLengths(i,:)<=pathlength & pathLengths(i,:)>0));
    [triangleQuality, bestAnchors] = findAnchorTriangle(tempT,find(t.nodeIDs==i), pathLengths);
    while triangleQuality>1 & length(tempT.anchorNodes) < totalAnchors %find the smallest path length for which this node is connected to at least 3 anchors
        pathlength = pathlength + 1;
        tempT.anchorNodes = t.nodeIDs((pathLengths(i,:)<=pathlength & pathLengths(i,:)>0));
        [triangleQuality, bestAnchors] = findAnchorTriangle(tempT,find(t.nodeIDs==i), pathLengths);
    end
    nonAnchors = vectorFind(setdiff(t.nodeIDs, bestAnchors), t.nodeIDs);
    tempT.kd(i,nonAnchors) = 0; %and only use those paths to anchors
    tempT.kd(nonAnchors,i) = 0; %and only use those paths to anchors
    pathLengths(i,nonAnchors) = 0; %and only use those paths to anchors
    pathLengths(nonAnchors,i) = 0; %and only use those paths to anchors
end
tempT.anchorNodes = t.anchorNodes;
tempT = leastSquaresMultilateration(tempT);
% tempT.kd = shortestPaths*scalingFactor;
% tempT = forceResolution(tempT);
%tempT = weightedLeastSquaresMultilateration(tempT, 1./pathLengths);
t.xyEstimate = tempT.xyEstimate;