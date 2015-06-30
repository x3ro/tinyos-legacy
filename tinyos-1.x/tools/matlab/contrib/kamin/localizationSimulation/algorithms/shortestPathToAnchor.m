function t = shortestPathToAnchor(t)
%t = shortestPathToAnchor(t)
%
%This function finds the shortest path from each node to all of the anchor
%nodes.  then, it gives the node the position with the lease error given
%those distances

shortestPaths = -ones(size(t.kd));

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

% %calculate a correction factor
% anchorIndices = vectorFind(t.anchorNodes, t.nodeIDs);
% xy = t.xy(anchorIndices,1)+t.xy(anchorIndices,2)*1i;
% [X,Y] = meshgrid(xy);
% anchorDists = abs(X-Y);
% measuredDists = shortestPaths(anchorIndices, anchorIndices);
% scalingFactor = mean(median(anchorDists./measuredDists));
% shortestPaths = shortestPaths*scalingFactor;
% % scalingFactor = sum(anchorDists,2)./sum(measuredDists,2);
% % mobileNodes = find(vectorFind(setdiff(t.nodeIDs, t.anchorNodes), t.nodeIDs));
% % shortestPaths(mobileNodes, anchorIndices) = shortestPaths(mobileNodes, anchorIndices).*scalingFactor(:,ones(1,length(mobileNodes)))';


tempT = t;
tempT.kd = shortestPaths;
tempT = leastSquaresMultilateration(tempT);
%maxwt =max(pathLengths,[],2);
%tempT = weightedLeastSquaresMultilateration(tempT, 1./pathLengths);
t.xyEstimate = tempT.xyEstimate;